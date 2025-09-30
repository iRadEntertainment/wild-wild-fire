extends Control

const DESCR = [
"""The wildfire are finally out!
You did an incredible job pilot!
You will be promoted, how cool is that?""",

"""You manage to eject just in time, but the fire kept spreading.
A new fire started at the position of your impact, the recovery
team just pulled you out in time!
Some cities reported heavy damages, your mission has failed...""",

"""You manage to safely land at sea, but the fire kept spreading.
The recovery team came to your rescue as soon as they could.
Some cities reported heavy damages, your mission has failed...""",

"""With the airport destroyed you headed out to a different airport.
The wildfire kept spreading, the cities reported massive damages...""",
]



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	select_ending()


func select_ending() -> void:
	var title: String = ""
	var description: String = ""
	match Mng.end_game:
		Mng.EndGame.FIRE_ESTINGUISHED:
			title = "Wildfire tamed\nGood job"
			description = DESCR[0]
			%bgs.current_tab = 0
		Mng.EndGame.PLANE_CRASHED:
			title = "Canadair\ncrashed"
			description = DESCR[1]
			%bgs.current_tab = 1
		Mng.EndGame.PLANE_ON_SEA:
			title = "Emergency\nSea Landing"
			description = DESCR[2]
			%bgs.current_tab = 1
		Mng.EndGame.AIRPORT_DESTROYED:
			title = "Airport\ndestroyed"
			description = DESCR[3]
			%bgs.current_tab = 2
	
	%lb_main.text = title
	%lb_description.text = description


func _on_btn_return_pressed() -> void: Mng.go_to_main_menu()
func _on_btn_credits_pressed() -> void: %pnl_credits.show()
func _on_btn_quit_pressed() -> void: Mng.quit()
