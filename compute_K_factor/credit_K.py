from typing import Dict, List
import pandas as pd

def credit_K_interprocessing(results:pd.DataFrame, 
                                flexible_units:List, 
                                dict_K0:Dict[str, float], 
                                dict_A_i:Dict[str, Dict[str, float]], 
                                dict_B_j:Dict[str, Dict[str, float]]):
    """Returns the corrected dataframe of crédit K after conservative horizon optimization.

    Parameters
    ----------
    results : pd.DataFrame
        pandas dataframe in which the results of the past rolling horizon are read.
    flexible_units : List
        List of FlexibleNPP in which are contained: name, p_max, efficiency, fuel_weight and ELPO_mode
    dict_K0 : Dict
        Start credit K value
    dict_A_i : Dict
        Credit K coefficients
    dict_B_j : Dict
        Credit K coefficients

    Returns
    -------
    pd.DataFrame
        pandas dataframe in which the credit K value was updated
    """
    new_results = results.copy()
    
    for flexible_unit in flexible_units:
        mode = flexible_units[flexible_unit].ELPO_mode
        name = flexible_units[flexible_unit].name

        print(f"Post treatment of unit {flexible_unit} in mode {mode}")

        for past_step_index in range(len(results)):
            past_step_is_ELPO = results.loc[past_step_index, name+"_is_step_ELPO"]

            if past_step_index - 1 < 0:
                past_past_step_creditELPO = dict_K0[mode]
                # print(f"Initialized past step crédit: {past_past_step_creditELPO}")
            else:
                past_past_step_creditELPO = new_creditK
                # print(f"Fetched in loop past step crédit: {past_past_step_creditELPO}")
            # end if

            if past_step_is_ELPO:
                # Debit credit K according to burn-up and power level
                if True:
                    past_step_power = results.loc[past_step_index, name+"_electricity"]
                    past_step_fpd = results.loc[past_step_index, name+"_fpd"]
                    past_step_burnup = (past_step_fpd * flexible_units[flexible_unit].p_max / flexible_units[flexible_unit].efficiency) / flexible_units[flexible_unit].fuel_weight

                    if past_step_burnup <= 2000:
                        if past_step_power < 0.85 * flexible_units[flexible_unit].p_max:
                            A_i = dict_A_i["0 to 2000 MWj/t"]["27 %Pn to 85 %Pn"]
                        else:
                            A_i = dict_A_i["0 to 2000 MWj/t"]["85 %Pn to 92 %Pn"]
                        # end if
                    elif past_step_burnup <= 6000:
                        if past_step_power < 0.85 * flexible_units[flexible_unit].p_max:
                            A_i = dict_A_i["2000 to 6000 MWj/t"]["27 %Pn to 85 %Pn"]
                        else:
                            A_i = dict_A_i["2000 to 6000 MWj/t"]["85 %Pn to 92 %Pn"]
                        # end if
                    else:
                        if past_step_power < 0.5 * flexible_units[flexible_unit].p_max:
                            A_i = dict_A_i["6000 MWj/t to end"]["27 %Pn to 50 %Pn"]
                        else:
                            A_i = dict_A_i["6000 MWj/t to end"]["50 %Pn to 92 %Pn"]
                        # end if
                    # end if

                    B_j = 0
                # end if True to collapse crédit K coefficients for ELPO

            else:
                if True:
                    past_step_PO = results.loc[past_step_index, name+"_PO"]

                    if past_step_PO:
                        if mode == "Base":
                            if past_past_step_creditELPO <= 100:
                                B_j = dict_B_j[mode]["0 to 100"][0] + dict_B_j[mode]["0 to 100"][1] * past_past_step_creditELPO
                            elif past_past_step_creditELPO <= 199:
                                B_j = dict_B_j[mode]["100 to 200"][0] + dict_B_j[mode]["100 to 200"][1] * past_past_step_creditELPO
                            else:
                                B_j = dict_B_j[mode]["200"][0] + dict_B_j[mode]["200"][1] * past_past_step_creditELPO
                            # end if
                        elif mode == "Load-following":
                            if past_past_step_creditELPO <= 80:
                                B_j = dict_B_j[mode]["0 to 80"][0] + dict_B_j[mode]["0 to 80"][1] * past_past_step_creditELPO
                            elif past_past_step_creditELPO <= 150:
                                B_j = dict_B_j[mode]["80 to 150"][0] + dict_B_j[mode]["80 to 150"][1] * past_past_step_creditELPO
                            else:
                                B_j = dict_B_j[mode]["150"][0] + dict_B_j[mode]["150"][1] * past_past_step_creditELPO
                            # end if
                    else:
                        B_j = 0
                    # end if
                        
                    A_i = 0
                # end if True to collapse crédit K coefficients for non-ELPO
            # end if

            new_creditK = past_past_step_creditELPO - A_i / 24 + B_j / 24            
            new_results.loc[past_step_index, name+"_creditELPO"] = new_creditK
        # end for timesteps
    # end for units

    return new_results