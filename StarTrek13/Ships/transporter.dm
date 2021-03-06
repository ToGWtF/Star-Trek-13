
/obj/machinery/computer/transporter_control
	name = "transporter control station"
	icon = 'StarTrek13/icons/trek/star_trek.dmi'
	icon_state = "helm"
	dir = 4
	icon_keyboard = null
	icon_screen = null
	layer = 4.5
	var/list/retrievable = list()
	var/list/linked = list()
	var/list/tricorders = list()
	var/area/destinations = list() //where can we go, relates to overmap.dm
	var/turf/open/available_turfs = list()
//	var/turf/open/teleport_target = null

/obj/machinery/computer/transporter_control/proc/activate_pads()
	for(var/obj/machinery/trek/transporter/T in linked)
		T.teleport_target = pick(available_turfs)
		T.Send()

/obj/machinery/computer/transporter_control/proc/get_available_turfs(var/area/A)
	available_turfs = list()
	for(var/turf/open/T in A)
		available_turfs += T


/obj/machinery/computer/transporter_control/attack_hand(mob/user)
	var/A
	var/B
	B = input(user, "Mode:","Transporter Control",B) in list("send object","retrieve away team member", "cancel")
	switch(B)
		if("send object")
			if(linked.len)
				A = input(user, "Target", "Transporter Control", A) as null|anything in destinations //activate_pads works here!
				A = destinations[A]
				if(!A)
					A = pick(destinations)
			//	var/area/thearea = A //problem
				playsound(src.loc, 'StarTrek13/sound/borg/machines/transporter.ogg', 40, 4)
			//	get_available_turfs(thearea)
				activate_pads()
				for(var/obj/machinery/trek/transporter/T in linked)
					for(var/mob/M in T.loc)
						retrievable += M
			else
				to_chat(user, "<span class='notice'>There are no linked transporter pads</span>")
		if("retrieve away team member")
			var/C = input(user, "Beam someone back", "Transporter Control") as anything in retrievable
			if(!C in retrievable)
				return
			var/atom/movable/target = C
			playsound(src.loc, 'StarTrek13/sound/borg/machines/transporter.ogg', 40, 4)
			retrievable -= target
			for(var/obj/machinery/trek/transporter/T in linked)
				animate(target,'StarTrek13/icons/trek/star_trek.dmi',"transportout")
				playsound(target.loc, 'StarTrek13/sound/borg/machines/transporter2.ogg', 40, 4)
				playsound(src.loc, 'StarTrek13/sound/borg/machines/transporter.ogg', 40, 4)
				var/obj/machinery/trek/transporter/Z = pick(linked)
				target.forceMove(Z.loc)
				target.alpha = 255
				//Z.rematerialize(target)
				animate(Z,'StarTrek13/icons/trek/star_trek.dmi',"transportin")
                        //        Z.alpha = 255
				break
		if("cancel")
			return

/obj/machinery/computer/transporter_control/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/device/tricorder))
		var/obj/item/device/tricorder/S = I
		if(istype(S.buffer, /obj/machinery/trek/transporter))
			linked += S.buffer
			S.buffer = null
			to_chat(user, "<span class='notice'>Transporter successfully connected to the console.</span>")
		else if(!I in tricorders)
			S.transporter_controller = src
			tricorders += S
			user << "Successfully linked [I] to [src], you may now tag items for transportation"
		else
			user << "[I] is already linked to [src]!"
	else
		return 0

/obj/machinery/trek/transporter
	name = "transporter pad"
	density = 0
	anchored = 1
	can_be_unanchored = 0
	icon = 'StarTrek13/icons/trek/star_trek.dmi'
	icon_state = "transporter"
	anchored = TRUE
	var/turf/open/teleport_target = null
	var/obj/machinery/computer/transporter_control/transporter_controller = null

/obj/machinery/trek/transporter/proc/Warp(mob/living/target)
	if(!target.buckled)
		target.forceMove(get_turf(src))

/obj/machinery/trek/transporter/proc/Send()
//	if(teleport_target == null)
	//	teleport_target = GLOB.teleportlocs[pick(GLOB.teleportlocs)]
	flick("alien-pad", src)
	for(var/mob/living/target in loc)
		target.forceMove(teleport_target)

/obj/machinery/trek/transporter/proc/Retrieve(mob/living/target)
	flick("alien-pad", src)
	new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)
	Warp(target)

/obj/machinery/trek/transporter/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/device/tricorder))
		var/obj/item/device/tricorder/T = I
		T.buffer = src
		to_chat(user, "<span class='notice'>Transporter data successfully stored in the tricorder buffer.</span>")

/*
/obj/structure/trek/transporter
	name = "transporter pad"
	density = 0
	anchored = 1
	can_be_unanchored = 0
	icon = 'StarTrek13/icons/trek/star_trek.dmi'
	icon_state = "transporter"
	var/target_loc = list() //copied
	var/obj/machinery/computer/transporter_control/transporter_controller = null

/obj/structure/trek/transporter/proc/teleport(var/mob/M, available_turfs)
	animate(M,'StarTrek13/icons/trek/star_trek.dmi',"transportout")
	usr << M
	M.dir = 1
	transporter_controller.retrievable += M
	if(M in transporter_controller.retrievable)
		transporter_controller.retrievable -= M
	M.alpha = 0
	M.forceMove(pick(available_turfs))
//	animate(M)
	if(ismob(M))
		var/mob/living/L = M
		L.Stun(3)
		animate(M,'StarTrek13/icons/trek/star_trek.dmi',"transportin") //test with flick, not sure if it'll work! SKREE
	icon_state = "transporter"

/obj/structure/trek/transporter/proc/teleport_all(available_turfs)
	icon_state = "transporter_on"
	for(var/mob/M in get_turf(src))
		if(M != src)
			//anim(M.loc,'icons/obj/machines/borg_decor.dmi',"transportin")
			teleport(M, available_turfs)
			rematerialize(M)
	icon_state = "transporter"


/obj/structure/trek/transporter/proc/rematerialize(var/atom/movable/thing)
	//var/atom/movable/target = Target
	icon_state = "transporter_on"
	thing.alpha = 255
	playsound(thing.loc, 'StarTrek13/sound/borg/machines/transporter2.ogg', 40, 4)
	icon_state = "transporter"*/