"""This file contains the EESREP component that can be used as a Flexible nuclear powerplant.
This component can satisfy ramping, crédit K, duration_on, duration_off constraints.

Two types are initially implemented:

    -   Converter : the output corresponds to the input multiplied by an efficiency.
    -   Cluster : models the behavior of N machines, that can be turned on and off.
    
This file aims at adding nuclear specific component to better model their behavior"""

import pandas as pd
import numpy as np

from eesrep.components.generic_component import GenericComponent
from eesrep.eesrep_enum import TimeSerieType
from eesrep.eesrep_io import ComponentIO
from eesrep.solver_interface.generic_interface import GenericInterface

class FlexibleNPP(GenericComponent):
    """EESREP flexible power plant model : The output evolution can satisfy ramps, crédit K, duration_on, duration_off constraints."""

    def __init__(self, 
                 name:str,
                 fpd_init:float,
                 fpd_max:float,
                 endogenous_burn_up_approx:bool,
                 RS_duration:float,
                 date_end_RS:float,
                 bool_fpd:bool,
                 efficiency:float,
                 average_lf:float,
                 p_max:float,
                 duration_on:float,
                 duration_off:float,
                 fuel_weight:float,
                 opex:float,
                 turn_on_price:float,
                 ramp_up:float,
                 ramp_down:float,
                 bool_ramps:bool,
                 creditELPOmax:float,
                 bool_creditELPO:bool,
                 ELPO_mode:str,
                 K0:int,
                 cons_A_i:float,
                 bool_duration:bool,
                 some_ts:pd.DataFrame = pd.DataFrame()):
        
        self.name = name
        self.fpd_init = fpd_init
        self.fpd_max = fpd_max
        self.endogenous_burn_up_approx = endogenous_burn_up_approx
        self.RS_duration = RS_duration
        self.date_end_RS = date_end_RS
        self.bool_fpd = bool_fpd
        self.efficiency = efficiency
        self.average_lf = average_lf
        self.p_max = p_max
        self.p_min_off = 0
        self.duration_on = duration_on
        self.duration_off = duration_off
        self.fuel_weight = fuel_weight
        self.opex = opex
        self.turn_on_price = turn_on_price
        self.ramp_up = ramp_up
        self.ramp_down = ramp_down
        self.bool_ramps = bool_ramps
        self.creditELPOmax = creditELPOmax
        self.bool_creditELPO = bool_creditELPO
        self.ELPO_mode = ELPO_mode
        self.K0 = K0
        self.cons_A_i = cons_A_i
        self.bool_duration = bool_duration

        #   Necessary object, instanciate empty if not used
        self.time_series = {
            # "some_time_serie":{
            #     "type":TimeSerieType.INTENSIVE,
            #     "value":some_ts
            # } 
        }

        self.CS = ComponentIO(self.name, "CS", TimeSerieType.INTENSIVE, True)
        self.HS = ComponentIO(self.name, "HS", TimeSerieType.INTENSIVE, True)
        self.LPO = ComponentIO(self.name, "LPO", TimeSerieType.INTENSIVE, True)
        self.PO = ComponentIO(self.name, "PO", TimeSerieType.INTENSIVE, True)
        self.RS = ComponentIO(self.name, "RS", TimeSerieType.INTENSIVE, True)
        self.RS_days = ComponentIO(self.name, "RS_days", TimeSerieType.INTENSIVE, True)
        self.fpd = ComponentIO(self.name, "fpd", TimeSerieType.INTENSIVE, True)
        self.burn_up = ComponentIO(self.name, "burn_up", TimeSerieType.INTENSIVE, True)
        self.creditELPO = ComponentIO(self.name, "creditELPO", TimeSerieType.INTENSIVE, True)
        self.countLPO = ComponentIO(self.name, "countLPO", TimeSerieType.INTENSIVE, True)
        self.is_step_ELPO = ComponentIO(self.name, "is_step_ELPO", TimeSerieType.INTENSIVE, True)
        self.electricity = ComponentIO(self.name, "electricity", TimeSerieType.INTENSIVE, True)
        self.fuel = ComponentIO(self.name, "fuel", TimeSerieType.INTENSIVE, False)
        self.turn_on = ComponentIO(self.name, "turn_on", TimeSerieType.INTENSIVE, True)
        self.turn_off = ComponentIO(self.name, "turn_off", TimeSerieType.INTENSIVE, True)
        self.turn_on_count = ComponentIO(self.name, "turn_on_count", TimeSerieType.INTENSIVE, True)
        self.turn_off_count = ComponentIO(self.name, "turn_off_count", TimeSerieType.INTENSIVE, True)

    def io_from_parameters(self) -> dict:
        """Lists the component Input/Output.
        """
        return {
                    "RS" : self.RS,
                    "CS" : self.CS,
                    "HS" : self.HS,
                    "LPO" : self.LPO,
                    "PO" : self.PO,
                    "fpd" : self.fpd,
                    "burn_up" : self.burn_up,
                    "RS_days" : self.RS_days,
                    "creditELPO" : self.creditELPO,
                    "countLPO" : self.countLPO,
                    "is_step_ELPO" : self.is_step_ELPO,
                    "electricity" : self.electricity,
                    "fuel" : self.fuel,
                    "turn_on" : self.turn_on,
                    "turn_off" : self.turn_off,
                    "turn_on_count" : self.turn_on_count,
                    "turn_off_count" : self.turn_off_count,
                }

    def build_model(self,
        component_name:str,
        time_steps:list,
        time_series:pd.DataFrame,
        history:pd.DataFrame,
        model_interface:GenericInterface):
        """Builds the model at the current horizon.

        Parameters
        ----------
        component_name : str
            Component name to index the MILP variables
        time_steps : list
            List of the time steps length 
        time_series : pd.DataFrame
            Dataframe containing the time series values at the current horizon time steps.
        history : pd.DataFrame
            Dataframe with the variables of previous iterations if "continuity" is at true.
        model_interface : GenericInterface
            Solver interface used to provide the variables

        """

        if True:
            if len(history) == 0:
                if self.date_end_RS > 0:
                    if self.date_end_RS <= self.RS_duration:
                        # if the NPP component is instantiated directly in RS
                        previous_horizon_RS_days = self.RS_duration - self.date_end_RS
                        previous_horizon_fpd = self.fpd_max
                    else:
                        # if the NPP component is instantiated with positive burn-up
                        previous_horizon_RS_days = 0
                        previous_horizon_fpd = self.fpd_max * (1 - self.date_end_RS / self.fpd_max)
                else:
                    previous_horizon_RS_days = 0
                    previous_horizon_fpd = self.fpd_init
            else:
                previous_horizon_fpd = history.loc[len(history)-1, "fpd"]
                previous_horizon_RS_days = history.loc[len(history)-1, "RS_days"]
            # end if
            burn_up_horizon = previous_horizon_fpd/self.fpd_max
            # print(f"Burn-up horizon: {burn_up_horizon}")
        # end if True to collapse initial RS days calculation and burn_up_horizon calculation    

        # print(f"Previous horizon RS days for {component_name} : {previous_horizon_RS_days}")
        # print(f"Previous horizon fpd for {component_name} : {previous_horizon_fpd}")

        if self.endogenous_burn_up_approx:
            if len(history) > 0:
                approx_lf = history.loc[:len(history)-1, "electricity"].mean() / self.p_max
            else:
                approx_lf = self.average_lf
        else:
            approx_lf = self.average_lf
        # end if
            
        RS_starts_during_next_horizon = (previous_horizon_RS_days <= 0) and (previous_horizon_fpd + (approx_lf * len(time_steps) / 24) >= self.fpd_max)
        RS_ends_during_next_horizon = (previous_horizon_RS_days > 0) and (self.RS_duration - previous_horizon_RS_days <= len(time_steps) / 24)
        RS_all_next_horizon = (previous_horizon_RS_days > 0) and (self.RS_duration - previous_horizon_RS_days >= len(time_steps) / 24)

        if RS_starts_during_next_horizon:
            threshold_timestep = int((self.fpd_max - previous_horizon_fpd) / approx_lf * 24)
            # print(f"RS will start during current horizon for {component_name} around step {threshold_timestep}")
        # elif RS_ends_during_next_horizon:
        #     print(f"RS will end during current horizon for {component_name}")
        # elif RS_all_next_horizon:
        #     print(f"RS should cover all current horizon for {component_name}")
        # else:
        #     print(f"No RS should happen during current horizon for {component_name}")
        # end if

        variables = {}

        if True:
            if not RS_all_next_horizon:
                # if unit may run during next horizon, variables should be initialized
                variables["CS"] = model_interface.get_new_discrete_variable_list(component_name+"_CS_", len(time_steps), 0, 1)
                variables["HS"] = model_interface.get_new_discrete_variable_list(component_name+"_HS_", len(time_steps), 0, 1)
                variables["LPO"] = model_interface.get_new_discrete_variable_list(component_name+"_LPO_", len(time_steps), 0, 1)
                variables["PO"] = model_interface.get_new_discrete_variable_list(component_name+"_PO_", len(time_steps), 0, 1)

                variables["fpd"] = model_interface.get_new_continuous_variable_list(component_name+"_fpd_", len(time_steps), 0., self.fpd_max)
                variables["burn_up"] = model_interface.get_new_continuous_variable_list(component_name+"_burnup_", len(time_steps), 0., None)
                variables["creditELPO"] = model_interface.get_new_continuous_variable_list(component_name+"_creditELPO_", len(time_steps), 0., self.creditELPOmax)
                variables["countLPO"] = model_interface.get_new_continuous_variable_list(component_name+"_countLPO_", len(time_steps), 0., None)
                variables["is_step_ELPO"] = model_interface.get_new_discrete_variable_list(component_name+"_is_step_ELPO_", len(time_steps), 0, 1)
                variables["fuel"] = model_interface.get_new_continuous_variable_list(component_name+"_fuel_", len(time_steps), 0, None)
                variables["electricity"] = model_interface.get_new_continuous_variable_list(component_name+"_electricity_", len(time_steps), self.p_min_off, self.p_max)

                variables["turn_on"] = model_interface.get_new_continuous_variable_list(component_name+"_turn_on_", len(time_steps), 0., None)
                variables["turn_off"] = model_interface.get_new_continuous_variable_list(component_name+"_turn_off_", len(time_steps), 0., None)
                variables["turn_on_count"] = model_interface.get_new_continuous_variable_list(component_name+"_turn_on_count_", len(time_steps), None, None)
                variables["turn_off_count"] = model_interface.get_new_continuous_variable_list(component_name+"_turn_off_count_", len(time_steps), None, None)

                ratio_p_min_p_max_LPO = [0 for i in range(len(time_steps))]
                p_max_LPO_p_max = [0 for i in range(len(time_steps))]
                ratio_p_min_p_max_PO = [0 for i in range(len(time_steps))]
            # end if

            if RS_starts_during_next_horizon:
                # if unit goes into Refuelling Stop in the current horizon
                variables["RS"] = [0 for i in range(threshold_timestep)] + [1 for i in range(len(time_steps) - threshold_timestep)]
                variables["RS_days"] = [0 for i in range(threshold_timestep)] + [i/24 for i in range(len(time_steps) - threshold_timestep)]

            elif RS_ends_during_next_horizon:
                # if unit ends its Refuelling Stop in the current horizon
                variables["RS"] = [0 for i in range(len(time_steps))]
                variables["RS_days"] = [0 for i in range(len(time_steps))]

                for RS_hour in range(int(np.ceil(24 * (self.RS_duration - previous_horizon_RS_days)) + 1)):
                    variables["RS"][RS_hour] = 1
                    variables["RS_days"][RS_hour] = previous_horizon_RS_days + RS_hour
                # end for
                    
            elif RS_all_next_horizon:
                variables["CS"] = [0 for i in range(len(time_steps))]
                variables["HS"] = [0 for i in range(len(time_steps))]
                variables["LPO"] = [0 for i in range(len(time_steps))]
                variables["PO"] = [0 for i in range(len(time_steps))]

                variables["RS"] = [1 for i in range(len(time_steps))]
                variables["RS_days"] = [previous_horizon_RS_days + hour/24 for hour in range(len(time_steps))]

                variables["fpd"] = [0 for i in range(len(time_steps))]                                    # It resets here the fpd and burn-up
                variables["burn_up"] = [0 for i in range(len(time_steps))]
                variables["creditELPO"] = [self.K0 for i in range(len(time_steps))]
                variables["countLPO"] = [0 for i in range(len(time_steps))]
                variables["is_step_ELPO"] = [0 for i in range(len(time_steps))]
                variables["fuel"] = [0 for i in range(len(time_steps))]
                variables["electricity"] = [0 for i in range(len(time_steps))]

                variables["turn_on"] = [0 for i in range(len(time_steps))]
                variables["turn_off"] = [0 for i in range(len(time_steps))]
                variables["turn_on_count"] = [0 for i in range(len(time_steps))]
                variables["turn_off_count"] = [0 for i in range(len(time_steps))]
            else:
                # if unit has no Refuelling Stop in the current horizon
                variables["RS"] = [0 for i in range(len(time_steps))]
                variables["RS_days"] = [0 for i in range(len(time_steps))]
            # end if
        # end if True to collapse variable declaration

        ###################################################################################################
        ###################################################################################################
        ###################################################################################################
        ######################### Instantiation of constraints at each time_step ##########################
        ###################################################################################################
        ###################################################################################################
        ###################################################################################################
        if not RS_all_next_horizon:
            # if unit can be activated in the current horizon
            for i in range(len(time_steps)):
                if True:
                    # Intermediate assignement of the current step
                    current_step_elec = variables["electricity"][i]
                    current_step_RS = variables["RS"][i]
                    current_step_boolstate = 1 - variables["CS"][i] - variables["RS"][i]
                    current_step_fpd = variables["fpd"][i]
                    current_step_creditELPO = variables["creditELPO"][i]
                    current_step_countLPO = variables["countLPO"][i]
                    current_step_is_step_ELPO = variables["is_step_ELPO"][i]
                    current_turn_off = variables["turn_off"][i]
                    current_turn_on = variables["turn_on"][i]

                    # Intermediate assignement of the previous step
                    if i == 0:
                        # First step of the current horizon : the previous step may not exist and might be fetched in the history
                        if len(history) == 0:
                            # First time step of the first horizon
                            previous_step_elec = 0
                            preivous_step_boolstate = 0
                            previous_step_fpd = previous_horizon_fpd
                            previous_step_creditELPO = self.K0
                        else:
                            # First time step of a generic horizon
                            previous_step_elec = history.loc[len(history)-1,"electricity"]
                            preivous_step_boolstate = 1 - history.loc[len(history)-1,"CS"] - history.loc[len(history)-1,"RS"]
                            previous_step_fpd = history.loc[len(history)-1,"fpd"]
                            previous_step_creditELPO = history.loc[len(history)-1,"creditELPO"]
                            previous_turn_off_count = history.loc[len(history)-1,"turn_off_count"]
                            previous_turn_on_count = history.loc[len(history)-1,"turn_on_count"]
                    else:
                        # Generic time step of a generic horizon
                        previous_step_elec = variables["electricity"][i-1]
                        preivous_step_boolstate = 1 - variables["CS"][i-1] - variables["RS"][i-1]
                        previous_step_fpd = variables["fpd"][i-1]
                        previous_step_creditELPO = variables["creditELPO"][i-1]
                        previous_turn_off_count = variables["turn_off_count"][i-1]
                        previous_turn_on_count = variables["turn_on_count"][i-1]
                    # end if
                # end if True to collapse intermediate assignment of current_step and previous_step variables, and crédit K coefficients if enabled

                if True:
                    # Static constraint of imperfect transformation of inputs into outputs
                    model_interface.add_equality(left_term = variables["electricity"][i], 
                                                right_term = variables["fuel"][i]*self.efficiency)

                    # Mutual exclusivity of states
                    model_interface.add_equality(left_term = model_interface.sum_variables([
                                                                        variables["RS"][i],
                                                                        variables["CS"][i],
                                                                        variables["HS"][i],
                                                                        variables["LPO"][i],
                                                                        variables["PO"][i]
                                                                    ]),
                                                right_term = 1)
                    
                    ### Calculation of the evolution of the irradiation campaign in equivalent days at full power ("fpd")
                    if self.bool_fpd:
                        model_interface.add_equality(left_term = model_interface.sum_variables([
                                                                        current_step_fpd,
                                                                        -previous_step_fpd
                                                                    ]), 
                                                     right_term = current_step_elec/self.p_max/24)
                    # end if global_NPP_bool_fpd
                # end if True to collapse fundamental rules on state, input/output and jepp counting
                
                ### Calculation of the approximate instantaneous burn_up to calculate the local p_min according to the real burn_up at the begining of the horizon and the average load factor
                if True:
                    burn_up_approx = burn_up_horizon + (i/24*approx_lf)/self.fpd_max
                    # print(f"Burn-up au pas {i} : {burn_up_approx}")

                    # Adjusts the local jig for P_min in LPO
                    if burn_up_approx <= 0.1:
                        # No flexibility allowed right after the refueling shutdown
                        ratio_p_min_p_max_LPO[i] = 1
                        ratio_p_min_p_max_PO[i] = 1
                        p_max_LPO_p_max[i] = 1
                    elif burn_up_approx <= 0.65:
                        ratio_p_min_p_max_LPO[i] = 0.2
                        ratio_p_min_p_max_PO[i] = 0.92 - 1e-6
                        p_max_LPO_p_max[i] = ratio_p_min_p_max_PO[i]
                    elif burn_up_approx <= 0.9:
                        ratio_p_min_p_max_LPO[i] = 0.2 + (burn_up_approx-0.65) * (0.86-0.2)/(0.9-0.65)
                        ratio_p_min_p_max_PO[i] = 0.92 - 1e-6
                        p_max_LPO_p_max[i] = ratio_p_min_p_max_PO[i]
                    else:
                        ratio_p_min_p_max_LPO[i] = 0.86
                        ratio_p_min_p_max_PO[i] = 0.92 - 1e-6
                        p_max_LPO_p_max[i] = ratio_p_min_p_max_PO[i]
                    # end if

                    model_interface.add_equality(left_term = variables["burn_up"][i], 
                                                right_term = burn_up_approx)
                # end if True to collapse burn_up calculation
                
                if True:
                    # Static constraints of limited output range while running
                    model_interface.add_lower_than(left_term = variables["electricity"][i], 
                                                right_term = model_interface.sum_variables([
                                                                        #0 * variables["CS"][i],
                                                                        #0.02 * self.p_max * variables["HS"][i],
                                                                        p_max_LPO_p_max[i] * self.p_max * variables["LPO"][i],
                                                                        self.p_max * variables["PO"][i]
                                                                    ])
                                                                )

                    # Minimum power constraint with p_min varying at each time step
                    model_interface.add_greater_than(left_term = variables["electricity"][i], 
                                                    right_term = model_interface.sum_variables([
                                                                        #0 * variables["CS"][i],
                                                                        #0.02 * self.p_max * variables["HS"][i],
                                                                        self.p_max * ratio_p_min_p_max_LPO[i] * variables["LPO"][i],
                                                                        ratio_p_min_p_max_PO[i] * self.p_max * variables["PO"][i]
                                                                    ])
                                                                )
                # end if True to collapse output level jig according to state and burnup
                    
                if self.bool_duration:
                    # Counts the number turned on and off during the past timesteps
                    arr_turn_on = []
                    for j in range(self.duration_on-1):
                        if i-j >= 0:
                            arr_turn_on.append(variables["turn_on"][i-j])
                        elif len(history) > 0 and len(history)+i-j >= 0:
                            arr_turn_on.append(history["turn_on"].iloc[len(history)+i-j])

                    variables["turn_on_count"][i] = model_interface.sum_variables(arr_turn_on)

                    arr_turn_off = []
                    for j in range(self.duration_off-1):
                        if i-j >= 0:
                            arr_turn_off.append(variables["turn_off"][i-j])
                        elif len(history) > 0 and len(history)+i-j >= 0:
                            arr_turn_off.append(history["turn_off"].iloc[len(history)+i-j])

                    variables["turn_off_count"][i] = model_interface.sum_variables(arr_turn_off)
                
                    # Restricts the evolution of n_machine, turn_off and turn_on according to preivous timesteps
                    if i == 0 and len(history) == 0:
                        # On the first step of the first horizon, turn_on and turn_off are relaxed
                        pass
                    else:
                        # restricts turn off to the last n_machine running minus those forced on (turned on in the last duration_on steps)
                        model_interface.add_lower_than(left_term = current_turn_off,
                                                        right_term = model_interface.sum_variables([
                                                                        preivous_step_boolstate,
                                                                        -previous_turn_on_count
                                                                    ])
                                                                )
                        # restricts in the same way turn on
                        model_interface.add_lower_than(left_term = current_turn_on,
                                                        right_term = model_interface.sum_variables([
                                                                        1,
                                                                        -preivous_step_boolstate,
                                                                        -previous_turn_off_count
                                                                    ])
                                                                )
                    # end if

                    model_interface.add_equality(left_term = current_step_boolstate, 
                                                right_term = model_interface.sum_variables([
                                                                    preivous_step_boolstate,
                                                                    -current_turn_off,
                                                                    current_turn_on
                                                                ])
                                                            )
                # end if self.bool_duration
            
                if self.bool_ramps:
                    # Case first horizon:
                        # Ramping up: CS_i-16 cannot be fetched in history. Let's assume that CS_0 is a suitable value until i > 16
                        # Ramping down: relaxed, no constraint mentionned in EDF's STE
                    # Case generic horizon:
                        # Ramping up: CS_i-16 can be fetched in history until i > 16
                        # Ramping down: relaxed, no constraint mentionned in EDF's STE

                    # A working ramping down constraint code is provided below if needed but would require minor ajustements (relaxed if CS is not null at the current timestep)
                    
                    # Intermediate assignement of the boolean reflecting CS value at step i-16
                    if i <= 16:
                        # First sixteen steps of the current horizon : the "16-steps-before" step may not exist and might be fetched in the history
                        if len(history) == 0:
                            # Not fetchable because not yet defined, let's assume that the first value of the first horizon fits the purpose
                            ramp_if_CSd_16 = self.p_max + ((self.ramp_up - 1) * self.p_max) * variables["CS"][0] #model_interface.sum_variables([variables["CS"][0], variables["RS"][0]])
                        else:
                            # Fetchable in the history
                            ramp_if_CSd_16 = self.p_max + ((self.ramp_up - 1) * self.p_max) * history.loc[len(history)-1 + (i-16),"CS"] #model_interface.sum_variables([history.loc[len(history)-1 + (i-16),"CS"], history.loc[len(history)-1 + (i-16),"RS"]])
                        # end if
                    else:
                        # Fetchable in current horizon
                        ramp_if_CSd_16 = self.p_max + ((self.ramp_up - 1) * self.p_max) * variables["CS"][i-16] #model_interface.sum_variables([variables["CS"][i-16], variables["RS"][i-16]])
                    # end if

                    # Ramping up constraint, relaxed if CS is not null at the current-16 timestep
                    model_interface.add_lower_than(left_term = model_interface.sum_variables([
                                                                        current_step_elec,
                                                                        -previous_step_elec
                                                                    ]),
                                                    right_term = ramp_if_CSd_16)
                    # No more ramping down constraint
                    pass
                    ## Ramping down constraint, relaxed if CS is not null at the current timestep
                    #model_interface.add_lower_than(left_term = model_interface.sum_variables([
                    #                                                    previous_step_elec,
                    #                                                    -current_step_elec
                    #                                                ]),
                    #                            right_term = model_interface.sum_variables([
                    #                                                    self.p_max * self.ramp_down,
                    #                                                    (current_step_CS) * 1e9
                    #                                                ]))
                # end if self.bool_ramps
                    
                if self.bool_creditELPO:
                    # Intermediate evaluation of LPO duration on the 24 time steps before the current step
                    sommeLPO = []
                    for j in range(24):
                        if i-j >= 0:
                            sommeLPO.append(variables["LPO"][i-j])
                        elif len(history) > 0 and len(history)+i-j >= 0:
                            sommeLPO.append(history["LPO"].iloc[len(history)+i-j])
                        # end if
                    # end for
                    
                    model_interface.add_equality(left_term = current_step_countLPO,
                                                    right_term = model_interface.sum_variables(sommeLPO))

                    # Forces MILP solver to switch is_step_ELPO to 1 if countLPO is beyond "8 hours out of 24" threshold
                    model_interface.add_lower_than(left_term = model_interface.sum_variables([
                                                    current_step_countLPO,
                                                    - 15e3 * current_step_is_step_ELPO
                                                    ]),
                                                    right_term = 8)

                    # Only debits creditELPO conservatively with higher A_i coefficient value. Crediting is operated between horizons
                    model_interface.add_equality(left_term = model_interface.sum_variables([
                                                    current_step_creditELPO,
                                                    -previous_step_creditELPO
                                                    ]), 
                                                    right_term = - self.cons_A_i / 24 * current_step_is_step_ELPO
                                                )
                # end if self.bool_creditELPO
            # end for
        # end if
        
        

        objective = model_interface.sum_variables([val * 1e-6 for val in variables["is_step_ELPO"]] + [val2 * 1e-6 for val2 in variables["LPO"]] + [val3 * self.turn_on_price for val3 in variables["turn_on"]])
        
        return variables, objective
    
