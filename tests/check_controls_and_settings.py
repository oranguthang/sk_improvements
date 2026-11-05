"""Regression checks on the built 68000 code; requires unicorn==2.1.4.
Build the ROM first, then run this script with Python 3.
"""
import re
from pathlib import Path
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
from unicorn.m68k_const import *

ROOT=Path(__file__).resolve().parents[1]

class CPU:
    cache={}
    def __init__(self, root, rom, lst):
        key=(str(root),rom,lst,(root/rom).stat().st_mtime_ns,(root/lst).stat().st_mtime_ns)
        if key not in self.cache:
            self.cache[key]=((root/rom).read_bytes(),{m[1]:int(m[2],16)&0xffffffff for m in re.finditer(r'\b([\w.]+)\s*:\s*([0-9A-F]+)\s+[-A-Z]',(root/lst).read_text(errors='replace'))})
        self.rom,self.s=self.cache[key]
        self.uc=Uc(UC_ARCH_M68K,UC_MODE_BIG_ENDIAN)
        self.uc.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        self.uc.mem_map(0,0x800000);self.uc.mem_write(0,self.rom)
        self.uc.mem_map(0xFFFF0000,0x10000)
        self.uc.mem_map(0xA00000,0x20000);self.uc.mem_map(0xC00000,0x1000)
        self.uc.reg_write(UC_M68K_REG_SR,0x2700)
    def addr(self,a):return self.s[a] if isinstance(a,str) else a
    def w(self,a,v,n=1):self.uc.mem_write(self.addr(a),(v&((1<<(n*8))-1)).to_bytes(n,'big'))
    def r(self,a,n=1):return int.from_bytes(self.uc.mem_read(self.addr(a),n),'big')
    def reg(self,n,v):self.uc.reg_write(n,v)
    def call(self,name):
        self.reg(UC_M68K_REG_A7,0xFFFFF000);self.w(0xFFFFF000,0x7f0000,4)
        try:self.uc.emu_start(self.s[name],0x7f0000,count=1000000)
        except Exception as e:raise RuntimeError((name,hex(self.uc.reg_read(UC_M68K_REG_PC)))) from e
        assert self.uc.reg_read(UC_M68K_REG_PC)==0x7f0000,(name,hex(self.uc.reg_read(UC_M68K_REG_PC)))
        # Materialize Unicorn's lazy 68000 CCR through an actual MOVE SR.
        saved=self.uc.reg_read(UC_M68K_REG_D7)
        self.uc.mem_write(0x7f0000,b'\x40\xc7')
        self.uc.emu_start(0x7f0000,0x7f0002,count=1)
        sr=self.uc.reg_read(UC_M68K_REG_D7)
        self.reg(UC_M68K_REG_D7,saved)
        return not bool(sr&4)
    def skip(self,name,callback=None):
        def hook(uc,pc,size,user):
            if callback:callback(self)
            sp=uc.reg_read(UC_M68K_REG_A7)
            uc.reg_write(UC_M68K_REG_PC,self.r(sp,4));uc.reg_write(UC_M68K_REG_A7,sp+4)
        self.uc.hook_add(UC_HOOK_CODE,hook,begin=self.s[name],end=self.s[name])

def c3():return CPU(ROOT,'sonic3k.bin','sonic3k.lst')

def record(c,version,payload,magic):
    rec=magic+bytes([version,len(payload)])+bytes(payload)
    rec+=sum(rec).to_bytes(2,'big')
    start=c.s.get('SRAM_settings',0x200001)
    for i,b in enumerate(rec):c.w(start+2*i,b)

def settings():
    c=c3();c.call('Settings_Defaults');assert c.r('Cheat_super_music')==1
    c.w('Cheat_super_music',0);c.w('Cheat_all_emeralds',1);c.w('Cheat_super_emeralds',0)
    c.w('Player_option',5,2);c.call('Settings_Save');c.w('Player_option',0,2)
    c.call('Settings_Load')
    assert c.r('Cheat_super_music')==0 and c.r('Player_option',2)==5
    assert c.r('Cheat_all_emeralds')==1 and c.r('Cheat_super_emeralds')==0
    record(c,1,[1,1,1,10,1,1,4],b'S3DV');c.call('Settings_Load')
    assert c.r('Cheat_super_music')==1 and c.r('Cheat_super_emeralds')==1 and c.r('Player_option',2)==4

def music():
    c=c3();events=[]
    c.skip('Play_Music',lambda cpu:events.append(cpu.uc.reg_read(UC_M68K_REG_D0)&255))
    c.w('Cheat_super_music',0);c.call('Play_SuperMusic');assert not events
    c.w('Cheat_super_music',1);c.call('Play_SuperMusic');assert events==[c.s['mus_Invincibility']]
    events.clear();p=c.s['Player_1'];c.reg(UC_M68K_REG_A0,p);c.w(p+c.s['air_left'],30)
    c.w('Current_music',c.s['mus_AIZ1'],2);c.w('Boss_flag',1);c.w('Boss_resume_music',c.s['mus_EndBoss'])
    c.w('Music_playing',c.s['mus_Invincibility']);c.call('Super_RecoverMusic')
    assert events==[c.s['mus_EndBoss']]
    events.clear();c.w('Cheat_super_music',0);c.call('Super_RecoverMusic');assert not events
    c.reg(UC_M68K_REG_D0,c.s['mus_EndBoss']);c.call('Music_Track')
    c.reg(UC_M68K_REG_D0,c.s['mus_ExtraLife']);c.call('Music_Track')
    assert c.r('Music_playing')==c.s['mus_EndBoss']

def emeralds():
    for chaos,super_ in [(0,0),(1,0),(1,1)]:
        c=c3();c.w('Cheat_all_emeralds',chaos);c.w('Cheat_super_emeralds',super_)
        # Equality means the wrapper sees seven; absent genuine emeralds compare below seven.
        assert c.call('Cheat_CmpChaosEmeralds') is (not chaos)
        assert c.call('Cheat_CmpSuperEmeralds') is (not super_)
    c=c3();c.skip('Settings_Save');c.skip('Play_SFX')
    c.w('Debug_mode_cheat_counter',1,2);c.w('Ctrl_1_pressed',c.s['button_right_mask'])
    c.call('CheatsPage_Controls');assert c.r('Cheat_all_emeralds')==c.r('Cheat_super_emeralds')==1
    c.w('Debug_mode_cheat_counter',0,2);c.call('CheatsPage_Controls')
    assert c.r('Cheat_all_emeralds')==c.r('Cheat_super_emeralds')==0
    return {'tiers_independent':True,'menu_dependency':True}

def characters():
    for option,mode,partner in [(0,0,0),(1,1,0),(2,2,0),(3,3,0),(4,4,0),(5,3,1)]:
        c=c3();c.w('Player_option',option,2);c.call('ApplyPlayerOption')
        assert c.r('Player_mode',2)==mode and c.r('Knuckles_Tails_flag')==partner
        if partner:
            c.w(c.s['Player_1']+c.s['x_pos'],0x1800,2)
            c.w('Knuckles_partner_pending',0xff)
            c.w('Level_started_flag',1)
            c.w(c.s['Player_1']+c.s['routine'],2)
            c.w('Ctrl_1_locked',1)
            c.call('SpawnKnucklesPartner');assert c.r('Player_2',4)==0
            c.w('Ctrl_1_locked',0)
            c.call('SpawnKnucklesPartner');assert c.r('Player_2',4)==c.s['Obj_Tails']
            assert c.r(c.s['Player_2']+c.s['x_pos'],2)==0x7f00
            assert c.r('Knuckles_partner_pending')==0
            c.w('Current_zone_and_act',0x300,2)
            c.reg(UC_M68K_REG_A0,c.s['Player_2'])
            c.call('loc_13A10')
            assert c.r('Tails_CPU_routine',2)==2
    for before,direction,after in [(3,1,5),(5,1,0),(0,2,5),(5,2,3)]:
        c=c3();c.skip('Play_SFX');c.reg(UC_M68K_REG_D0,before);c.w('Ctrl_1_pressed',direction)
        c.call('sub_D6D0');assert c.uc.reg_read(UC_M68K_REG_D0)==after
    # Removing CHEATS must also remove left/right routes into its old row.
    for row in range(33):
        for direction in ['button_left_mask','button_right_mask']:
            c=c3();c.skip('Play_SFX');c.w('Level_select_option',row,2)
            c.w('Ctrl_1_pressed',c.s[direction]);c.call('LevSelControls_SwitchSide')
            assert c.r('Level_select_option',2)<33,(row,direction)
    return {'character_options':6,'save_menu_skips_blue':True,'partner_spawned':True}

def combo_cpu(mode,hyper_=False):
    c=c3();p=c.s['Player_1'];c.reg(UC_M68K_REG_A0,p)
    c.reg(UC_M68K_REG_A4,c.s['Max_speed_P2' if mode==2 else 'Max_speed'])
    c.w('Player_mode',mode,2);c.w('Cheat_all_emeralds',1);c.w('Cheat_super_emeralds',int(hyper_))
    c.w('Cheat_super_rings',50);c.w('Ring_count',50,2);c.w('Update_HUD_timer',1)
    for key,val in [('status',2|4),('jumping',1),('character_id',1 if mode==2 else 2 if mode>=3 else 0),('air_left',30)]:c.w(p+c.s[key],val)
    c.skip('Play_SFX');c.skip('Play_Music');c.skip('Play_Music_IfChanged')
    return c,p

def press(c,held,new):
    c.w('Ctrl_1_held_logical',held);c.w('Ctrl_1_pressed_logical',new)
    return c.call('Player_SuperCombo')

def combos():
    for mode in [0,1,2,3,4]:
        for hyper_ in [False,True]:
            for buttons in [(0x40,0x10),(0x40,0x20),(0x10,0x20)]:
                c,p=combo_cpu(mode,hyper_);a,b=buttons
                assert not press(c,a,a)
                assert press(c,a|b,b),('combo did not transform',mode,hyper_,buttons)
                flag='Super_Tails_flag' if mode==2 else 'Super_Sonic_Knux_flag'
                assert c.r(flag)==(255 if hyper_ and mode!=2 else 1)
                if mode==2:assert bool(c.r('Invincibility_stars',4))==hyper_
                c.w(p+c.s['object_control'],0);c.w(p+c.s['double_jump_flag'],1)
                c.w(p+c.s['x_vel'],0x380,2);c.w(p+c.s['y_vel'],0x100,2)
                press(c,0,0);press(c,a,a);assert press(c,a|b,b)
                assert c.r(flag)==0 and c.r(p+c.s['double_jump_flag'])==1
                assert c.r(p+c.s['x_vel'],2)==0x380 and c.r(p+c.s['y_vel'],2)==0x100
    c,p=combo_cpu(2);press(c,0x40,0x40)
    for _ in range(11):press(c,0x40,0)
    c.w(p+c.s['double_jump_flag'],1)
    assert not press(c,0x60,0x20) and c.r('Super_Tails_flag')==0
    return {'transform_and_revert_cases':30,'velocity_and_ability_preserved':True,'late_flight_combo_rejected':True}

def god_and_ai():
    for competition in [0,1]:
        for slot in ['Player_1','Player_2']:
            c=c3();c.w('Cheat_god_mode',1);c.w('Competition_mode',competition,2)
            c.reg(UC_M68K_REG_A0,c.s[slot]);c.reg(UC_M68K_REG_A2,c.s[slot])
            want=slot=='Player_1'
            assert c.call('Cheat_GodModePlayer')==want and c.call('Cheat_GodModeAir')==want
            c.w('Demo_mode_flag',1,2);assert not c.call('Cheat_GodModePlayer')
    c=c3();c.reg(UC_M68K_REG_A0,c.s['Player_2']);c.w('Current_zone_and_act',1,2);c.w('Events_routine_bg',20,2)
    c.reg(UC_M68K_REG_D1,0x400);c.call('Tails_FollowBombingRun');assert c.uc.reg_read(UC_M68K_REG_D1)==0x800
    c.w('Tails_CPU_idle_timer',1,2);c.reg(UC_M68K_REG_D1,0x400);c.call('Tails_FollowBombingRun');assert c.uc.reg_read(UC_M68K_REG_D1)==0x400
    return {'competition_p1_only':True,'demo_protection_disabled':True,'bombing_run_ai_continues_right':True,'human_p2_preserved':True}

def signpost():
    c=c3();plcs=[];c.w('Debug_mode_flag',1)
    c.skip('Load_PLC_Raw',lambda cpu:plcs.append(cpu.uc.reg_read(UC_M68K_REG_A1)))
    c.call('Signpost_DebugArt');assert plcs==[c.s['PLC_EndSignStuff']]

def damage_and_debug():
    for character in range(3):
        for slot in ['Player_1','Player_2']:
            c=c3();p=c.s[slot]
            c.reg(UC_M68K_REG_A0,p);c.reg(UC_M68K_REG_A2,c.s['Dynamic_object_RAM'])
            c.w('Competition_mode',1,2);c.w('Cheat_god_mode',1)
            c.w(p+c.s['routine'],2);c.w(p+c.s['character_id'],character)
            c.w(p+c.s['y_pos'],0x100,2);c.w('Camera_max_Y_pos',0x800,2)
            c.skip('Play_SFX');c.call('HurtCharacter')
            assert (c.r(p+c.s['routine'])==2)==(slot=='Player_1'),(character,slot)
            if slot=='Player_1':
                c.w(p+c.s['y_pos'],0x8E1,2);c.call('Kill_Character')
                assert c.r(p+c.s['y_vel'],2)==0xF600 and c.r(p+c.s['routine'])==2
    for slot in ['Player_1','Player_2']:
        c=c3();p=c.s[slot];c.reg(UC_M68K_REG_A0,p)
        c.w('Ctrl_1_pressed',c.s['button_B_mask']);c.w('Ctrl_1',c.s['button_B_mask'])
        assert c.call('Player_DebugButton')==(slot=='Player_1')
        c.w(p+c.s['status'],2);c.w('Ctrl_1',c.s['button_B_mask']|c.s['button_A_mask'])
        assert not c.call('Player_DebugButton'),'a Super combo entered debug'
    for slot,field in [('Player_1','Competition_time_record'),('Player_2','Competition_time_record_P2')]:
        c=c3();p=c.s[slot];hud='Update_HUD_timer' if slot=='Player_1' else 'Update_HUD_timer_P2'
        c.w('Cheat_god_mode',1);c.w('Competition_mode',1,2)
        c.w(field,0x093b63,4);c.w(hud,1)
        c.reg(UC_M68K_REG_A4,c.s[hud]);c.reg(UC_M68K_REG_A5,c.s[field])
        c.skip('loc_37DB0');c.skip('loc_37DD0');c.call('loc_37D7C')
        assert c.r(hud)==(1 if slot=='Player_1' else 0x80)
    # The native carry must use Knuckles' hang pose and preserve the hold.
    c=c3();p=c.s['Player_1'];q=c.s['Player_2'];f=c.s['Flying_carrying_Sonic_flag']
    c.reg(UC_M68K_REG_A0,q);c.reg(UC_M68K_REG_A1,p);c.reg(UC_M68K_REG_A2,f)
    c.w(p+c.s['character_id'],2);c.w(q+c.s['x_pos'],0x200,2);c.w(q+c.s['y_pos'],0x100,2)
    c.call('sub_1459E');assert c.r(p+c.s['anim'])==0x14
    c.w(f,1);c.reg(UC_M68K_REG_D0,0);c.skip('SonicKnux_DoLevelCollision');c.skip('Perform_Player_DPLC')
    c.call('Tails_Carry_Sonic');assert c.r(f)==1 and c.r(p+c.s['mapping_frame'])==0x91

def silent_menus():
    for row in range(7):
        c=c3();sounds=[];c.skip('Play_SFX',lambda cpu:sounds.append(1));c.skip('Settings_Save')
        c.w('Debug_mode_cheat_counter',row,2);c.w('Ctrl_1_pressed',c.s['button_right_mask'])
        c.call('CheatsPage_Controls');assert not sounds,('Cheats beep',row)
    c=c3();sounds=[];c.skip('Play_SFX',lambda cpu:sounds.append(1))
    c.w('Level_select_option',30,2);c.w('Ctrl_1_pressed',c.s['button_right_mask'])
    c.call('LevelSelect_SpecialStageLR');assert not sounds
    assert c.r('Current_special_stage')==1


if __name__=='__main__':
    settings();music();signpost();damage_and_debug();silent_menus()
    print(emeralds());print(characters());print(combos());print(god_and_ai())
    print('S3K checks passed')
