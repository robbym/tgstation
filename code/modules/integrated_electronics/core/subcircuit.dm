/obj/item/integrated_circuit/subcircuit_interface
	name = "subcircuit interface"
	removable = FALSE

/obj/item/integrated_circuit/subcircuit_interface/check_interactivity(mob/user)
	return TRUE





/obj/item/device/electronic_assembly/subcircuit_internal
	var/obj/item/integrated_circuit/subcircuit_interface/interface = new
	opened = TRUE
	subcircuit = TRUE

/obj/item/device/electronic_assembly/subcircuit_internal/Initialize()
	. = ..()
	interface.forceMove(get_object())
	interface.assembly = src
	assembly_components |= interface

/obj/item/device/electronic_assembly/subcircuit_internal/check_interactivity(mob/user)
	return TRUE





/obj/item/integrated_circuit/subcircuit
	name = "subcircuit assembly"
	category_text = "Assemblies"

	var/obj/item/device/electronic_assembly/subcircuit_internal/internal = new

	inputs = list("A","B")
	outputs = list("A","B")
	activators = list("in 1" = IC_PINTYPE_PULSE_IN, "in 2" = IC_PINTYPE_PULSE_IN, "out 1" = IC_PINTYPE_PULSE_OUT, "out 2" = IC_PINTYPE_PULSE_OUT)

/obj/item/integrated_circuit/subcircuit/attack_self(mob/living/user)
	internal.attack_self(user)

/obj/item/integrated_circuit/subcircuit/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/device/integrated_electronics/wirer))
		modify(user)
		return TRUE
	if(istype(I, /obj/item/integrated_circuit) && !istype(I, /obj/item/integrated_circuit/input) && !istype(I, /obj/item/integrated_circuit/output))
		return internal.attackby(I, user)
	return FALSE

/obj/item/integrated_circuit/subcircuit/proc/modify(mob/user)
	var/window_height = 350
	var/window_width = 655

	var/table_edge_width = "30%"
	var/table_middle_width = "40%"

	var/HTML = ""
	HTML += "<html><head><title>[src.displayed_name]</title></head><body>"
	HTML += "<div align='center'>"
	HTML += "<table border='1' style='undefined;table-layout: fixed; width: 80%'>"

	HTML += "<a href='?src=[REF(src)];edit=1;rename=1'>\[Rename\]</a>"
	HTML += "<br>"

	HTML += "<colgroup>"
	HTML += "<col style='width: [table_edge_width]'>"
	HTML += "<col style='width: [table_middle_width]'>"
	HTML += "<col style='width: [table_edge_width]'>"
	HTML += "</colgroup>"

	var/column_width = 3
	var/row_height = max(inputs.len, outputs.len, 1)

	for(var/i = 1 to row_height)
		HTML += "<tr>"
		for(var/j = 1 to column_width)
			var/datum/integrated_io/io = null
			var/words = list()
			var/height = 1
			switch(j)
				if(1)
					io = get_pin_ref(IC_INPUT, i)
					if(io)
						words += "<b><a href='?src=[REF(src)];edit=1;pin=[REF(io)];change=1'>[io.display_pin_type()]</a> <a href='?src=[REF(src)];edit=1;pin=[REF(io)];rename=1'>[io.name]</a></b><br>"

						if(outputs.len > inputs.len)
							height = 1
				if(2)
					if(i == 1)
						words += "[src.displayed_name]<br>[src.name != src.displayed_name ? "([src.name])":""]<hr>[src.desc]"
						height = row_height
					else
						continue
				if(3)
					io = get_pin_ref(IC_OUTPUT, i)
					if(io)
						words += "<b><a href='?src=[REF(src)];edit=1;pin=[REF(io)];change=1'>[io.display_pin_type()]</a> <a href='?src=[REF(src)];edit=1;pin=[REF(io)];rename=1'>[io.name]</a></b><br>"

						if(inputs.len > outputs.len)
							height = 1
			HTML += "<td align='center' rowspan='[height]'>[jointext(words, null)]</td>"
		HTML += "</tr>"

	for(var/activator in activators)
		var/datum/integrated_io/io = activator
		var/words = list()

		words += "<b><font color='FF0000'><a href='?src=[REF(src)];edit=1;pin=[REF(io)];rename=1'>[io]</a></font> "
		words += "<font color='FF0000'><a href='?src=[REF(src)];edit=1;pin=[REF(io)];change=1'>[io.data?"\<OUT\>":"\<IN\>"]</a></font></b><br>"

		HTML += "<tr>"
		HTML += "<td colspan='3' align='center'>[jointext(words, null)]</td>"
		HTML += "</tr>"

	HTML += "</table>"
	HTML += "</div>"

	HTML += "<br><font color='0000AA'>[extended_desc]</font>"

	HTML += "</body></html>"

	user << browse(HTML, "window=subcircuit-[REF(src)];size=[window_width]x[window_height];border=1;can_resize=1;can_close=1;can_minimize=1")

/obj/item/integrated_circuit/subcircuit/Topic(href, href_list)
	if(!href_list["edit"])
		..(href, href_list)
	else
		if(href_list["pin"])
			var/datum/integrated_io/pin = locate(href_list["pin"]) in inputs + outputs + activators
			if(!pin)
				return

			if(href_list["rename"])
				var/input = reject_bad_name(stripped_input(usr, "What do you want to name this?", "Rename", pin.name), TRUE)
				if(input)
					pin.name = input

			if(href_list["change"])
				if(pin in inputs + outputs)
					var/type_to_use = input("Please choose a type to use.", "Pin Type") as null | anything in list("any", "string", "char", "color", "number", "dir", "boolean", "ref", "list", "index")
					var/list/pin_list = (pin in inputs) ? inputs : outputs
					var/index = pin_list.Find(pin)
					pin_list.Cut(index, index+1)
					switch(type_to_use)
						if("any")
							pin_list.Insert(index, new IC_PINTYPE_ANY(src, pin.name, pin.data, pin.type, pin.ord))
						if("string")
							pin_list.Insert(index, new IC_PINTYPE_STRING(src, pin.name, pin.data, pin.type, pin.ord))
						if("char")
							pin_list.Insert(index, new IC_PINTYPE_CHAR(src, pin.name, pin.data, pin.type, pin.ord))
						if("color")
							pin_list.Insert(index, new IC_PINTYPE_COLOR(src, pin.name, pin.data, pin.type, pin.ord))
						if("number")
							pin_list.Insert(index, new IC_PINTYPE_NUMBER(src, pin.name, pin.data, pin.type, pin.ord))
						if("dir")
							pin_list.Insert(index, new IC_PINTYPE_DIR(src, pin.name, pin.data, pin.type, pin.ord))
						if("boolean")
							pin_list.Insert(index, new IC_PINTYPE_BOOLEAN(src, pin.name, pin.data, pin.type, pin.ord))
						if("ref")
							pin_list.Insert(index, new IC_PINTYPE_REF(src, pin.name, pin.data, pin.type, pin.ord))
						if("list")
							pin_list.Insert(index, new IC_PINTYPE_LIST(src, pin.name, pin.data, pin.type, pin.ord))
						if("index")
							pin_list.Insert(index, new IC_PINTYPE_INDEX(src, pin.name, pin.data, pin.type, pin.ord))
				else
					pin.data = !pin.data

				update_interface()
		else
			if(href_list["rename"])
				src.rename_component()

	modify(usr)

/obj/item/integrated_circuit/subcircuit/proc/update_interface()
	internal.interface.inputs.Cut()
	internal.interface.outputs.Cut()
	internal.interface.activators.Cut()

	for(var/datum/integrated_io/pin in inputs)
		internal.interface.outputs.Add(new pin.type(internal.interface, pin.name, pin.data, IC_OUTPUT, pin.ord))

	for(var/datum/integrated_io/pin in outputs)
		internal.interface.inputs.Add(new pin.type(internal.interface, pin.name, pin.data, IC_INPUT, pin.ord))

	for(var/datum/integrated_io/pin in activators)
		internal.interface.activators.Add(new /datum/integrated_io/activate(internal.interface, pin.name, !pin.data, pin.type, pin.ord))

/obj/item/integrated_circuit/subcircuit/do_work(var/ord)
	for(var/I=1; I<=inputs.len; I++)
		internal.interface.set_pin_data(IC_OUTPUT, I, inputs[I].data)
	internal.interface.push_data()
	internal.interface.activate_pin(ord)