//Balor Grinder LMG
class BalorLMG:Balor{
	default{
		health 700;
		height 52;
		radius 32;
		mass 600;
		painchance 128;
		+map07boss2
		+floorclip
		+bossdeath
		+lookallaround
		+hdmobbase.headless
		+hdmobbase.onlyscreamondeath
		seesound "baby/sight";
		painsound "baby/pain";
		activesound "baby/active";
		tag "$TAG_BALORLMG";
		+dontharmspecies +missilemore
		obituary "$OB_BALORLMG";
		speed 10;
		deathheight 18;
		+noblooddecals bloodtype "NotQuiteBloodSplat";
		hdmobbase.shields 250;
		meleethreshold -128;
		translation "16:47=112:127", "192:207=112:125", "224:231=195:203", "160:167=196:203";
	}
	override void postbeginplay(){
		if(bplayingid)blookallaround=false;
		else gunheight=height*0.8;
		super.postbeginplay();
		battery=20;
//		alt=random(0,1);
	}
	override void deathdrop(){
		if(!bhasdropped){
			bhasdropped=true;
			let mmm=HDMagAmmo.SpawnMag(self,"HDBattery",battery);
			mmm.vel=vel+(frandom(-1,1),frandom(-1,1),1);
			if(!random(0,28))A_DropItem("Putto");
		}
	}
	int battery;
//	bool alt;
	
	static void LaserZap(
		actor caller,
		double zoffset=32,
		int battery=20,
		double sm1=0,
		double sm2=0,
		double focus=300 
	){
		//determine angle
		double shootangle=caller.angle;
		double shootpitch=caller.pitch;
		vector3 shootpos=(0,0,zoffset);
		let hdp=hdplayerpawn(caller);
		if(hdp){
			shootangle=hdp.gunangle;
			shootpitch=hdp.gunpitch;
			shootpos=hdp.gunpos;
		}
		shootangle+=sm1;
		shootpitch+=sm2;

		//create the line
		flinetracedata tlt;
		caller.linetrace(
			shootangle,
			8000+200*battery,
			shootpitch,
			flags:TRF_NOSKY|TRF_ABSOFFSET,
			offsetz:shootpos.z,
			offsetforward:shootpos.x,
			offsetside:shootpos.y,
			data:tlt
		);


		if(
			tlt.hittype==Trace_HitNone
			||(
				tlt.hitline&&(
					tlt.hitline.special==Line_Horizon
					||(
						tlt.linepart==2
						&&tlt.hitsector.gettexture(0)==skyflatnum
					)||(
						tlt.linepart==1
						&&tlt.hitline.sidedef[1]
						&&hdmath.oppositesector(tlt.hitline,tlt.hitsector).gettexture(0)==skyflatnum
					)
				)
			)
		)return;

		//alt does a totally different thing
		if(tlt.hittype==Trace_HitNone||tlt.distance>HD_BEAMLASERMAXRANGE)return;
		actor bbb=spawn("BeamGunSpotFlash",tlt.hitlocation-tlt.hitdir,ALLOW_REPLACE);
		bbb.setz(clamp(bbb.pos.z,bbb.floorz,bbb.ceilingz-8));
		if(!random(0,3))(lingeringthunder.zap(bbb,bbb,caller,40,true));
		
		double fuck;
		if(tlt.distance > focus)
		{
			fuck = tlt.distance - focus;
		}
		else if(tlt.distance <= focus)
		{
			fuck = focus - tlt.distance;
		}
		BeamGunSpotFlash(bbb).impactdistance=clamp(fuck, 0, 1500);//-16*battery;
		if(hd_debug)
		{caller.a_logint(fuck);
		caller.a_logint(tlt.distance);}
		
		//BeamGunSpotFlash(bbb).impactdistance=tlt.distance-16*battery;
		bbb.angle=caller.angle;
		bbb.A_SprayDecal("Scorch",12);
		bbb.pitch=caller.pitch;
		bbb.target=caller;
		bbb.tracer=tlt.hitactor; //damage inflicted on the puff's end
		if(tlt.hitline)doordestroyer.CheckDirtyWindowBreak(tlt.hitline,0.005*battery,tlt.hitlocation);
		
		double dist = int(tlt.Distance);	
		actor laser = Spawn("BeamGunLaser", caller.pos+shootpos-(0,0,1));
		BeamGunLaser(laser).angle = shootangle;
		BeamGunLaser(laser).pitch = shootpitch*-1 - 90;
		BeamGunLaser(laser).scale.y = dist/112;//clamp(dist, 0, 128);*/
		BeamGunLaser(laser).alpha = 1.0 - clamp(fuck, 0, 800)*0.001;
		
		actor fx = Spawn("BeamGunLaserFX", caller.pos+shootpos-(0,0,1));
		BeamGunLaserFX(fx).alpha = 1.0 - clamp(fuck, 0, 800)*0.001;
		
		Spawn("BeamSpotFlashLight", caller.pos+shootpos-(0,0,1));
		caller.A_StopSound(CHAN_7);
		caller.A_StartSound("weapons/lasermgfire", CHAN_WEAPON);
	}
	
	void A_ThunderZap(int focus = HDCONST_ONEMETRE*7.5){
		if(battery<1){
			setstatelabel("mustreload");
			return;
		}
		A_StartSound("weapons/lasermgidle", CHAN_7);
		LaserZap(
			self,
			20,
			battery,
			0,
			0,
			focus
		);
		if(!random(0,6))battery--;
	}
	override void A_HDChase(
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){
		if(
			!(flags&CHF_DONTMOVE)
			&&(frame==0||frame==2||frame==4)
		)A_StartSound("baby/walk",CHAN_BODY,CHANF_OVERLAP);
		super.A_HDChase(meleestate,missilestate,flags,speedmult);
	}
	states{
	ambushrotate:
		---- A 0 A_StartSound("baby/walk");
		BSPI A 8 A_HDLook();
		BSPI B 8 A_SetAngle(angle+frandom(-12,12));
		BSPI C 8 A_HDLook();
		BSPI D 8 A_SetAngle(angle+frandom(-12,12));
	ambush:
		BSPI C 10 A_HDLook();
		---- A 0 A_Jump(28,"ambushrotate");
	spawn:
		BSPI A 0 A_JumpIf(bambush,"ambush");
		BSPI CCC 10 A_HDLook();
		---- A 0 A_Jump(192,"spawn","ambushrotate");
	spawnwander:
		BSPI ABC 8 A_HDWander();
		---- A 0 A_SetAngle(angle+frandom(-8,8));
		BSPI DEF 8 A_HDWander();
		---- A 0 A_SetAngle(angle+frandom(-8,8));
		---- A 0 A_Jump(28,"spawn");
		loop;

	see:
		---- A 0 {
			if(A_JumpIfCloser(500,"null")){
				bmissilemore=false;
				bfrightened=true;
				alt=false;
			}else{
				bmissilemore=true;
				bfrightened=false;
				alt=false;
			}
			bambush=0;
		}
		BSPI ABCDEF 4 A_HDChase();
		---- A 0 A_JumpIfTargetInLOS("see");
	roam:
		BSPI AB 6 A_HDWander();
		BSPI C 6 A_HDWander(CHF_LOOK);
		---- A 0 A_Jump(48,"roamc");
	roam2:
		BSPI D 6 A_HDWander(CHF_LOOK);
		BSPI EF 6 A_HDWander();
		---- A 0 A_Jump(48,"roamf");
		---- A 0 A_JumpIfTargetInLOS("roamc");
		goto roam;
	roamc:
		BSPI C 4 A_HDChase("missile","missile",CHF_DONTMOVE);
		BSPI CCC 2 A_HDChase("missile","missile",CHF_DONTMOVE);
		---- A 0 A_Jump(48,1);
		loop;
		---- A 0 A_StartSound("baby/walk");
		goto roam2;
	roamf:
		BSPI F 4 A_HDChase("missile","missile",CHF_DONTMOVE);
		BSPI FFF 2 A_HDChase("missile","missile",CHF_DONTMOVE);
		---- A 0 A_Jump(48,"roam");
		loop;

	missile:
		---- A 0 A_StartSound("baby/walk");
		BSPI AB 5 A_TurnToAim(20,targetheight:(frandom(0,target.height*0.6)));
		---- A 0 A_StartSound("baby/walk");
//		---- A 0 A_JumpIf(!HDMobAI.TryShoot(self,flags:hdmobai.TS_GEOMETRYOK),"see");
		BSPI CD 5 A_TurnToAim(20,targetheight:(frandom(0,target.height*0.6)));
		---- A 0 A_StartSound("baby/walk");
		BSPI EF 5 A_TurnToAim(20,targetheight:(frandom(0,target.height*0.6)));
		loop;
	shoot:
		BSPI A 1 A_StartAim(mintics:4,maxtics:20,dontlead:false);
		BSPI A 8{
			angle+=frandom(-spread,spread);
			pitch+=frandom(-spread,spread);
			if(!HDMobAI.TryShoot(self,gunheight,max(abs(meleethreshold),lasttargetdist-300))){
				setstatelabel("pain");
				return;
			}
			A_FaceTarget(6*(distance3d(target)/150),6*(distance3d(target)/150));
			alt=false;
		}
		BSPI GG 2 bright light("PLAZMABX2")A_StartSound("weapons/plasidle",CHAN_WEAPON);
	shootpb2:
		BSPI GHGHGHGH 4 bright light("PLAZMABX2"){
			A_ThunderZap(distance3d(target)+random(-45,5));
			if(target&&distance3d(target)>random(0,150))
				A_FaceTarget(3*(distance3d(target)/150),3*(distance3d(target)/150));
				
				//3*(distance3d(target)/150)
		}
		---- A 0 A_Watch();
		---- A 0 setstatelabel("see");
		---- A 0 A_Jump(48,"shootpb2");
		---- A 0 setstatelabel("see");
	mustreload:
		BSPI H 10;
	reload:
		BSPI ABCDEF 4 A_HDChase(null,null,CHF_FLEE);
		BSPI AA 2 A_StartSound("baby/walk",CHAN_BODY);
		BSPI AAAAAAAA 6{
			vector3 bbb=pos+((cos(angle),sin(angle))*radius,42);
			for(int i=0;i<3;i++){
				double aaa=frandom(0,360);
				double ppp=frandom(-90,70);
				double cp=cos(ppp);
				vector3 vvv=(cp*cos(aaa),cp*sin(aaa),-sin(ppp));
				vector3 vvv2=vvv*frandom(20,40);
				let fff=spawn("FragShard",bbb+vvv2,ALLOW_REPLACE);
				fff.vel=vel-vvv;
			}
			A_StartSound("weapons/plasidle",CHAN_WEAPON,CHANF_OVERLAP);
			battery+=2;
		}
		BSPI A 8 A_StartSound("baby/sight",CHAN_WEAPON,CHANF_OVERLAP);
		BSPI A 0 {
			battery=20;
			setstatelabel("see");
		}
	pain:
		BSPI I 3;
		BSPI I 3 A_Vocalize(painsound);
		BSPI I 0{
			if(target&&target.distance3d(self)<abs(meleethreshold)){
				let aaa=spawn("idledummy",target.pos);
				threat=aaa;
				aaa.stamina=35;
			}
		}
		---- A 0 setstatelabel("see");
	death:
		---- AAAAAAAA 0 A_SpawnItemEx("HugeWallChunk",frandom(-4,4),frandom(-4,4),frandom(28,34),frandom(-6,6),frandom(-6,6),frandom(-2,16),0,160,0);
		---- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk",frandom(-3,3),frandom(-3,3),frandom(28,34),frandom(-2,2),frandom(-2,2),frandom(2,14),0,160,0);
		BSPI J 4 A_StartSound("baby/death",CHAN_BODY);
		BSPI J 6 A_SpawnItemEx("MegaBloodSplatter",frandom(-10,10),frandom(-10,10),32,0,0,0,0,160,0);
		BSPI J 10 A_SpawnItemEx("MegaBloodSplatter",frandom(-4,4),frandom(-4,4),32,0,0,0,0,160,0);
		BSPI KLMN 7 A_SpawnItemEx("MegaBloodSplatter",0,0,28,0,0,0,0,160,0);
		---- A 0 A_SpawnItemEx("MegaBloodSplatter",0,0,14,0,0,0,0,160,0);
		BSPI O 7;
		BSPI P -1 A_BossDeath();
	xdeath:
		stop;
	raise:
		BSPI PONMLKJ 5;
		BSPI I 8;
		BSPI I 0 A_StartSound(seesound);
		BSPI AAABB 3 A_Chase(null,null);
		#### A 0 A_Jump(256,"see");
	death.maxphdrain:
		---- AAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk",frandom(-3,3),frandom(-3,3),frandom(28,34),frandom(-2,2),frandom(-2,2),frandom(2,14),0,160,0);
		BSPI J 10;
		BSPI KLMNO 7;
		BSPI P -1;
	}
}