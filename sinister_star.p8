pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--game loop

function _init()
 ticks=0
 game_setup()
end

function _update()
 if not game_over and not win
  then
   ticks+=1
   move_player()
   move_bullets()
   set_dir_enemy(
    ticks,workers,70,true,31
   )
   set_dir_enemy(
    ticks,soldiers,200,false,47
   )
   move_objects(workers)
   move_objects(asteroids)
   move_soldiers()
   move_sinibombs()
   collision(ticks)
  if is_sinistar then
   move_sinistar()
  end
 end
end

function _draw()
 cls()
 draw_game()
end
-->8
--setup and collision code

function game_setup()
 make_player()
 game_over=false
 win=false
 is_sinistar=false
 respawn_cooldown=false

 asteroids={}
 for i=1,20,1 do
  make_asteroid(true)
 end

 workers={}
 for i=1,15,1 do
  make_worker(true)
 end

 soldiers={}
 for i=1,10,1 do
  make_soldier(true)
 end

 bullets={}
 --mined sinibombs
 sinibombs={}
 --active seeking sinibombs
 starbombs={}
 effects={}

 objects={
  asteroids,workers,soldiers,
  bullets,sinibombs,starbombs,
  effects
 }
end

function collision(ticks)
 --player collision
 for b in all(bullets) do
  if b.player==0 then
   if proximity(p,b,0.5) then
    game_over=true
    sfx(2)
    camera(200,200)
   end
  end
 end
 
 if is_sinistar then
  if proximity(p,star,2) then
   game_over=true
   sfx(2)
   camera(200,200)
  end
 end

 for s in all(sinibombs) do
  if proximity(p,s,0.5) then
   if p.sinibombs<10 then
    p.sinibombs+=1
   end
   del(sinibombs,s)
  end
 end

 --player bullet collision
 for b in all(bullets) do
  if b.player==1 then

   for a in all(asteroids) do
    if proximity(b,a,0.9) then
     sfx(3)
     a.hp=a.hp-1
     if a.hp<=0 then
      make_sinibomb(a)
      make_asteroid(false)       
      del(asteroids,a)
     end
     hit_effect(b)
    end
   end
    
   for w in all(workers) do
    if proximity(b,w,0.4) then
     sfx(2)
     respawn_cooldown=true
     del(workers,w)
     hit_effect(b)
    end
   end
   
   for s in all(soldiers) do
    if proximity(b,s,0.4) then
     sfx(2)
     respawn_cooldown=true
     del(soldiers,s)
     hit_effect(b)
    end
   end
  end
 end
 
 if respawn_cooldown==true then
  if ticks%30==0 then
   spawn_enemy()
   respawn_cooldown=false
  end
 end
end

function hit_effect(b)
 add(
  effects,{
   x=b.x,y=b.y,dur=5,timer=0
  }
 )
 del(bullets,b)
end

function spawn_enemy()
 local prob=flr(rnd(100))
 if prob<75 then
  make_worker(false)
 else
  make_soldier(false)
 end
end

-->8
--animation code

function draw_game()
 if win then
  print("you win",250,264,7)
 elseif game_over then
  print("game over",246,264,7)
 else
  draw_map()
  draw_objects(bullets)
  draw_asteroids(ticks)
  draw_objects(workers)
  draw_objects(soldiers)
  draw_sinibombs()
  draw_player()
  if is_sinistar then
   draw_sinistar()
   print(
    "beware, i live...",8,8,7
   )
  end
  draw_effects()
 end
end

function draw_map()
 map(16,16,0,0,48,48)
 
 for class in all(objects) do
  for i in all(class) do
   wrap_screen(i)
  end
 end
end

function draw_player()
 spr(p.sprite,p.x*8,p.y*8)
end

function draw_asteroids(ticks)
 for a in all(asteroids) do
  if (ticks%10==0) then
   a.sprite=(a.sprite+1)%24
   if a.sprite==0 then
    a.sprite=16
   end
  end
  spr(a.sprite,a.x*8,a.y*8)
 end
end

function draw_objects(class)
 for obj in all(class) do
  spr(
   obj.sprite,obj.x*8,obj.y*8
  )
 end
end

function draw_sinibombs()
 for s in all(sinibombs) do
  spr(60,s.x*8,s.y*8)
 end
 for s in all(starbombs) do
  spr(60,s.x*8,s.y*8)
 end
 for i=1,p.sinibombs,1 do
  spr(60,(16-i)*8,15*8)
 end
end

function draw_sinistar()
 local offsetx=-1
 local offsety=-1
 local a=1 --sprite counter
 for i=1,3,1 do
  for j=0,2,1 do
   sprite=star.pieces[a]
   local x=star.x+offsetx
   local y=star.y+offsety
   spr(sprite,x*8,y*8)
   offsetx+=1
   a+=1
  end
  offsetx=-1
  offsety+=1
 end
end

function draw_effects()
 for e in all(effects) do
  spr(58,e.x*8,e.y*8)
  e.timer+=1
  if e.timer>=e.dur then
   del(effects,e)
  end
 end
end

function wrap_screen(obj)
 if obj.x<-8 then
  obj.x=24
 elseif obj.x>24 then
  obj.x=-8
 end
 if obj.y<-8 then
  obj.y=24
 elseif obj.y>24 then
  obj.y=-8
 end
end

function set_dir_sprite(
 obj,base,x,y
)
 if (x<0.05 and x>0) or
  (x>-0.05 and x<0) then
   x=0
 end
 
 if (y<0.05 and y>0) or
  (y>-0.05 and y<0) then
   y=0
 end

 new_sprite=0
	if (x==0 and y>0) then
	 new_sprite=1
	elseif (x<0 and y>0) then
	 new_sprite=2	 
	elseif (x<0 and y==0) then
	 new_sprite=3
	elseif (x<0 and y<0) then
	 new_sprite=4
	elseif (x==0 and y<0) then
	 new_sprite=5
	elseif (x>0 and y<0) then
  new_sprite=6
	elseif (x>0 and y==0) then
	 new_sprite=7
	elseif (x>0 and y>0) then
	 new_sprite=8
 end
 
 if x==0 and y==0 then
  base=obj.sprite
 end

 obj.sprite=base+new_sprite
end

-->8
--shared object code

function cooldown(obj,threshold)
 obj.cooldown+=1
 if obj.cooldown>=threshold then
  obj.cooldown=0
 end
end

function proximity(a,b,dist)
 if abs(a.x-b.x)<dist and
  abs(a.y-b.y)<dist then
   return true
 else
  return false
 end
end

function random_spawn(
 max_dir,in_view
)
 local min_dir=-max_dir/2
 local spawn={}
  
 spawn.x=rnd(48)
 spawn.y=rnd(48)
 
 if not in_view then
  while proximity(spawn,p,9) do
   spawn.x=rnd(48)
   spawn.y=rnd(48)
  end
 end
 
 spawn.dirx=min_dir+rnd(max_dir)
 spawn.diry=min_dir+rnd(max_dir)
 spawn.seed=flr(rnd(50))
 return spawn
end

function move_objects(class)
 for obj in all(class) do
  obj.x+=obj.dirx
  obj.y+=obj.diry
 end
end

function set_dir_enemy(
 ticks,class,thresh,mine,s_base
)
 for e in all(class) do
  if (e.offset+ticks)%thresh==0
   then
    if mine then
     mine_asteroid(e)
    end
    e.dirx=rnd(0.4)-0.2
    e.diry=rnd(0.4)-0.2
    set_dir_sprite(
     e,s_base,e.dirx,e.diry
    )
  end
 end
end

--translated from unity's
--vector2.movetowards()
--originally written in c#
function move_towards(
 obj,target,speed
)
 local distx=target.x-obj.x
 local disty=target.y-obj.y
 local sqdist=
  distx*distx+disty*disty
 
 if sqdist==0 or
  sqdist<=speed*speed then
   obj.x=target.x
   obj.y=target.y
   return
 end

 local dist=sqrt(sqdist)
 obj.x=obj.x+distx/dist*speed
 obj.y=obj.y+disty/dist*speed
end
-->8
--player code

function make_player()
 p={}
 p.x=7.5
 p.y=7.5
 p.dirx=0
 p.diry=0.2
 p.sprite=1
 p.cooldown=0
 p.sinibombs=0
 p.starpieces=0
 --sinistar pieces taken by
 --workers
end

function move_player()
 local dirx=0
 local diry=0
 
	if btn(⬅️) then
		dirx=0.2
	elseif btn(➡️) then
	 dirx=-0.2
	end
	
	if btn(⬆️) then
		diry=0.2
	elseif btn(⬇️) then
	 diry=-0.2
	end

 if p.cooldown==0 then
  if btn(❎) then
   make_bullet(
    p,-p.dirx,-p.diry,1.5,1
   )
   cooldown(p,10)
  end
  if btn(🅾️) then --also "c"
   if p.sinibombs>0 then
    fire_sinibomb(p)
    cooldown(p,10)
    p.sinibombs-=1
   end
  end
 else
  cooldown(p,10)
 end
 
 if dirx!=0 or diry!=0 then
  p.dirx=dirx
  p.diry=diry
 end

 set_dir_sprite(p,0,dirx,diry)
 move_relative(dirx,diry)
end

function move_relative(
 dirx,diry
)
 for class in all(objects) do
  for i in all(class) do
   i.x+=dirx
   i.y+=diry
  end
 end
 if is_sinistar then
  star.x+=dirx
  star.y+=diry
 end
end
-->8
--asteroid and bullet code

function make_asteroid(is_setup)
 local r=random_spawn(
  0.02,is_setup
 )
 local sprite=flr(rnd(8))+16
 add(
  asteroids,{
   x=r.x,y=r.y,dirx=r.dirx,hp=3,
   diry=r.diry,sprite=sprite
  }
 )
end

function mine_asteroid(obj)
 for a in all(asteroids) do
  if proximity(a,obj,1.5) then
   del(asteroids,a)
   make_asteroid(false)
   p.starpieces=p.starpieces+1
   if p.starpieces>=30 and
    not is_sinistar then
     sfx(4)
     is_sinistar=true
     make_sinistar()
   end
  end
 end
end

function make_bullet(
 obj,dirx,diry,spd,player
)
 sfx(0)
 add(
  bullets,{
   x=obj.x,y=obj.y,sprite=59,
   dirx=dirx*spd,diry=diry*spd,
   player=player
  }
 )
end

function move_bullets()
 for b in all(bullets) do
  b.x+=b.dirx
  b.y+=b.diry
  if abs(p.x-b.x)>7 or
  abs(p.y-b.y)>7 then
   del(bullets,b)
  end
 end
end
-->8
--enemy code

function make_worker(is_setup)
 local r=random_spawn(
  0.4,is_setup
 )
 add(
  workers,{
   x=r.x,y=r.y,dirx=r.dirx,
   diry=r.diry,offset=r.seed,
   sprite=32
  }
 )
end

function make_soldier(is_setup)
 local r=random_spawn(
  0.2,is_setup
 )
 add(
  soldiers,{
   x=r.x,y=r.y,dirx=r.dirx,
   diry=r.diry,offset=r.seed,
   found_p=0,cooldown=0,
   sprite=48
  }
 )
end

function move_soldiers()
 for s in all(soldiers) do
  if s.found_p==0 then
   if proximity(p,s,3) then
    s.found_p=1
   end
   s.x+=s.dirx
   s.y+=s.diry
  else
   local offsetx=(p.x-s.x)*0.1
   local offsety=(p.y-s.y)*0.1
   cooldown(s,60)
   if abs(p.x-s.x)>4 or
    abs(p.y-s.y)>4 then
     s.found_p=0
   end
   if s.cooldown<40 then
    move_towards(s,p,0.2)
    set_dir_sprite(
     s,47,offsetx,offsety
    )
   end
   if s.cooldown==45 then
    make_bullet(
     s,offsetx,offsety,1.5,0
   )
   end
  end
 end
end
-->8
--sinister star code

function make_sinibomb(obj)
 add(
  sinibombs,{x=obj.x,y=obj.y}
 )
end

function fire_sinibomb(obj)
 sfx(1)
 add(
  starbombs,{
   x=obj.x,y=obj.y,cooldown=0
  }
 )
end

function move_sinibombs()
 for s in all(starbombs) do
  cooldown(s,65)
  if s.cooldown>=60 then
   del(starbombs,s)
  end
  if is_sinistar then
   move_towards(s,star,0.3)
   if proximity(s,star,1.8) then
    sfx(5)
    del(starbombs,s)
    star.health-=1
    if star.health<=0 then
     win=true
     camera(200,200)
    end
   end
  end
 end
end

function make_sinistar()
 star={}
 star.flag=0
 star.x=rnd(48)
 star.y=rnd(48)
 star.cooldown=0
 star.health=15
 star.pieces={
  13,14,15,29,30,31,45,46,47
 }
 add(objects,star)
end

function move_sinistar()
 cooldown(star,100)
 if star.cooldown<60 then
  move_towards(star,p,0.27)
 else
  move_towards(star,p,0.05)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056659966666659950000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566656666666656665000
0007700000077000000c7000000c7000000cc000000cc000000cc0000007c0000007c00000000000000000000000000000000000005666666666666666666500
00077000000cc000000cc000000c7000000c7000000770000007c0000007c000000cc00000000000000000000000000000000000056666666666666666666650
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000596666666666666666666665
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000596668886666666688866665
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555668888666666888866555
00444400004444000044440000444400004444000044440000444400004444000000000000000000000000000000000000000000566668888866668888866695
0444444004444440044444400444444004444440044444400444444004444440000000000000000000000000000000000000000056666888a866668a88866695
44444444446644444446644444446644444444444444444444444444444444440000000000000000000000000000000000000000566666888866668888666665
44644444446444444444444444444644444446444444444444444444444444440000000000000000000000000000000000000000566666666666666666666665
44644444444444444444444444444444444446444444464444444444446444440000000000000000000000000000000000000000566666666666666666666665
44444444444444444444444444444444444444444444664444466444446644440000000000000000000000000000000000000000566666666666666666666665
04444440044444400444444004444440044444400444444004444440044444400000000000000000000000000000000000000000596688666666666666886665
00444400004444000044440000444400004444000044440000444400004444000000000000000000000000000000000000000000596681888888888888186665
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555668111111111111866555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566666881111111188666695
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566666668888888866666695
000bb000000bb0000007b0000007b00000077000000b7000000b7000000bb0000000000000000000000000000000000000000000056666666666666666666650
000770000007b0000007b000000bb000000bb000000bb000000b7000000b70000000000000000000000000000000000000000000005666666666666666666500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566656666666656665000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000059956666669956650000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000990000000000000000000000000000000000000000000
00088000000880000007800000078000000770000008700000087000000880000000000000000000009aa900000ee000000aa000000000000000000000000000
00077000000780000007800000088000000880000008800000087000000870000000000000000000009aa900000ee000000aa000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000990000000000000000000000000000000000000000000
__sfx__
00010000135502255023500255002650027500295002a5002a5002b50028500275000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000035100450033400396003e6003760021600066000060026600236001f60019600126000c6000b600072000820009200092000a2000a2000b200122000e20000000000000000000000000000000000000
001000000062002620026100060006600006000060002600006001b70016700107000970009700006000060000600000000000000000000000000000000000000000000000000000000000000000000000000000
001000000121001200012000120001200012000120002200022000220002200012000120001200012000120002200022000220002200032000320003200022000220002200022000220002200012000120000000
001000003d2503e2503d2503e2503e2503e2503e2503e2503c2503b2503c2503b250392503b230372203521002200002000120031600386003e6003f6003e6003c6003b600386003760037600356000000000000
00100000364503845038450384503a4503d3002630026300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
