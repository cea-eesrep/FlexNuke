import pandas as pd

from compute_K_factor.cython_credit_K import credit_K_interprocessing as cython_function
from compute_K_factor.credit_K import credit_K_interprocessing as python_function
from FlexibleNPP_component import FlexibleNPP

dict_K0 = {"Base" : 200, "Load-following" : 100}
dict_A_i = {"0 to 2000 MWj/t" : {"27 %Pn to 85 %Pn" : 4.9, "85 %Pn to 92 %Pn" : 2.8},
    "2000 to 6000 MWj/t" : {"27 %Pn to 85 %Pn" : 6.1, "85 %Pn to 92 %Pn" : 2.3},
    "6000 MWj/t to end" : {"27 %Pn to 50 %Pn" : 4.1, "50 %Pn to 92 %Pn" : 6.3}
    }
conservative_A_i = max([max(dict_A_i[key].values()) for key in dict_A_i.keys()])
dict_B_j = {"Base" : {"0 to 100" : [8, -0.07], "100 to 200" : [1, 0], "200" : [0, 0]},
            "Load-following" : {"0 to 80" : [4.5, -0.05], "80 to 150" : [0.5, 0], "150" : [0, 0]}
            }

Flexible_units = {}

name = "Flexible_Nuke_1"
global_NPP_bool_creditELPO = True

### NPP caracteristics (most reference values found in ITESE A-B use case)
NPP_cycle_duration_fpd = 300            # Duration of the irradiation campaign in full power equivalent days
NPP_RS_duration = 26                    # Standard duration of the refueling stop
NPP_efficiency = 0.33                   # Fuel to electricity ratio, no cogeneration considered
NPP_average_lf = 0.81                   # Average load factor during a campaign
NPP_P_max = 1086.                       # Average nominal power (electric) in the french fleet
NPP_P_min_rel = 0.4                     # Minimum relative output before shutdown
NPP_fuel_weight = 0.002 * 264 * 185     # Weight of the fuel in core (tons) : 2kg * 264 fuel rods * 185 assemblies (average)
NPP_duration_on = 12                    # Minimum time enabled after turning on
NPP_duration_off = 16                   # Minimum time disabled after turning off
NPP_ramp_up = 0.03                      # Maximum ramping up rate after Cold Shutdown and refueling/repositioning stops
NPP_ramp_down = 1                       # Maximum ramping down rate

### Clusterized NPP caracteristics
N1 = 10                                 # Number of NPP in the cluster

### Economic value
NPP_OPEX = 14.5                         # Cost of energy (€/MWh)
NPP_turn_on_price = 28. * NPP_P_max     # Cost of switching on (€/MW) multiplied by maximum power
NPP_FOPEX = 0.01                        # Default to disable NPPs when useless (€/h)

global_NPP_bool_ramps = False
dict_K_max = {"Base" : 200, "Load-following" : 150}
ELPO_mode = ["Load-following", "Load-following", "Load-following"]
global_NPP_bool_duration = True
Units_dates_RS = [0,0] # [22, 30, 0]
i = 1

Flexible_units[name] = FlexibleNPP(name = name,
                                    fpd_init = 0,
                                    fpd_max = NPP_cycle_duration_fpd,
                                    endogenous_burn_up_approx = True,
                                    RS_duration = NPP_RS_duration,
                                    date_end_RS = Units_dates_RS[1],
                                    bool_fpd = True,
                                    efficiency = NPP_efficiency,
                                    average_lf = NPP_average_lf,
                                    p_max = NPP_P_max,
                                    duration_on = NPP_duration_on,
                                    duration_off = NPP_duration_off,
                                    fuel_weight= NPP_fuel_weight,
                                    opex = NPP_OPEX,
                                    turn_on_price = NPP_turn_on_price,
                                    ramp_up = NPP_ramp_up,
                                    ramp_down = NPP_ramp_down,
                                    bool_ramps = global_NPP_bool_ramps,
                                    creditELPOmax = dict_K_max[ELPO_mode[i]],
                                    bool_creditELPO = global_NPP_bool_creditELPO,
                                    ELPO_mode = ELPO_mode[i],
                                    K0 = dict_K0[ELPO_mode[i]],
                                    cons_A_i = conservative_A_i,
                                    bool_duration = global_NPP_bool_duration)

df = pd.read_csv("test/data_test_credit_K.csv")

df2 = python_function(df, Flexible_units, dict_K0, dict_A_i, dict_B_j)

df3 = cython_function(df, Flexible_units, dict_K0, dict_A_i, dict_B_j)

assert df2[name+"_creditELPO"].all() == df3[name+"_creditELPO"].all()