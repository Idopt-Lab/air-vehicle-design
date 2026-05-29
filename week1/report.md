### General Mission Idea

Each simulation run goes through these common steps:

1. On Ground Roll.  V0 - V1 : Aircraft on the ground goes from initial v0 to v1 speed. Both engines at takeoff power
2. Continued Roll to rotation speed. V1 - Vr: Aircraft still on ground accelerates from V1 speed to Vr speed, committed to take off now
3. Rotation.: Aircraft lifts off and starts climbing to 35ft altitude, 2 other phases at this point are also checked. 
4. Balanced field solve:  This finds v1 such that, the distance to clear the 35ft obstacle is equal to the distance when stopped at v1 to reach a complete stop. Checks if taking off at this speed is safe or not. 
5. Engine Out Climb. : If one of the engine fails, can aircraft still climb the 35 ft altitude. 
6. Climb: Aircrfat climbs at constant airspeed and vertical speed to reach cruising altitude. 
7. Cruise: aircraft flies at cruising altitude and constant airspeed.
8. Descent: Aircraft descents at constant airspeed and vertical speed to reach sea level at exact mission range. 



### Defined Input values for KING_AIR_C90GT:

| Variable Name         | Value  | Unit   | Description                        |
|-----------------------|--------|--------|------------------------------------|
| climb.fltcond\|vs     | 1500   | ft/min | Climb vertical speed               |
| climb.fltcond\|Ueas   | 124    | kn     | Climb airspeed (EAS)               |
| cruise.fltcond\|vs    | 0.01   | ft/min | Cruise vertical speed (near zero)  |
| cruise.fltcond\|Ueas  | 170    | kn     | Cruise airspeed (EAS)              |
| descent.fltcond\|vs   | -600   | ft/min | Descent vertical speed             |
| descent.fltcond\|Ueas | 140    | kn     | Descent airspeed (EAS)             |
| cruise\|h0            | 29,000 | ft     | Cruise altitude                    |
| mission_range         | 1000   | NM     | Total mission range                |
| payload               | 1000   | lb     | Payload (passengers + cargo)       |
| v1vr.throttle         | 0.75   | —      | Rotation throttle (derated)        |
| rotate.throttle       | 0.75   | —      | Liftoff throttle (derated)         |


## MTOW For KING_AIR_C90GT is defined in aircraft_data as 4581 Kg

### Mission for example KING_AIR_C90GT


King Air C90GT, starts at sea level with 1000 lb payload and 4581 Kg MTOW uses 65 percent of throttle power, it accelerates down the runway commits to takeoff at bfs speed, it cleares 35ft obstacle. It then climbs at 124 kn / 1500 ft/min to reach cruising altitude of 29,000 ft. It cruises at near 0 (0.01) vertical speed and and 170 kn airspeed. It then descends at 140 kn / -600 ft/min to reach back at sea level. The range of the total flight at this point is equal to mission range of 1000 NM 

## Output for KING_AIR_C90GT

MTOW: 10099.376230689242 lb
OEW: 6471.539115423346 lb
Fuel used: 1666.7345958167136 lb
TOFL (over 35ft obstacle): 3054.612797991232 ft




