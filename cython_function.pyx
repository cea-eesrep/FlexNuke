
cpdef credit_K_interprocessing_cython_typed(mode:str,
                                            pmax:float,
                                            efficiency:float,
                                            fuel_weight:float,
                                            elpo:list,
                                            is_elpo:list,
                                            is_po:list,
                                            elec:list,
                                            fpd:list,
                                            dict_K0:dict,
                                            dict_A_i:dict,
                                            dict_B_j:dict):
    """Returns the corrected dataframe of crédit K after conservative horizon optimization."""

    credit_k:list = []

    for past_step_index in range(len(elpo)):
        past_step_is_ELPO:float = elpo[past_step_index]

        if past_step_index - 1 < 0:
            past_past_step_creditELPO:float = dict_K0[mode]
        else:
            past_past_step_creditELPO:float = new_creditK

        if past_step_is_ELPO:
            past_step_power:float = elec[past_step_index]
            past_step_fpd:float = fpd[past_step_index]
            past_step_burnup:float = (past_step_fpd * pmax / efficiency) / fuel_weight

            if past_step_burnup <= 2000:
                if past_step_power < 0.85 * pmax:
                    A_i:float = dict_A_i["0 to 2000 MWj/t"]["27 %Pn to 85 %Pn"]
                else:
                    A_i:float = dict_A_i["0 to 2000 MWj/t"]["85 %Pn to 92 %Pn"]
            elif past_step_burnup <= 6000:
                if past_step_power < 0.85 * pmax:
                    A_i:float = dict_A_i["2000 to 6000 MWj/t"]["27 %Pn to 85 %Pn"]
                else:
                    A_i:float = dict_A_i["2000 to 6000 MWj/t"]["85 %Pn to 92 %Pn"]
            else:
                if past_step_power < 0.5 * pmax:
                    A_i:float = dict_A_i["6000 MWj/t to end"]["27 %Pn to 50 %Pn"]
                else:
                    A_i:float = dict_A_i["6000 MWj/t to end"]["50 %Pn to 92 %Pn"]

            B_j:float = 0

        else:
            past_step_PO:float = is_po[past_step_index]

            if past_step_PO:
                if mode == "Base":
                    if past_past_step_creditELPO <= 100:
                        B_j:float = dict_B_j[mode]["0 to 100"][0] + dict_B_j[mode]["0 to 100"][1] * past_past_step_creditELPO
                    elif past_past_step_creditELPO <= 199:
                        B_j:float = dict_B_j[mode]["100 to 200"][0] + dict_B_j[mode]["100 to 200"][1] * past_past_step_creditELPO
                    else:
                        B_j:float = dict_B_j[mode]["200"][0] + dict_B_j[mode]["200"][1] * past_past_step_creditELPO
                elif mode == "Load-following":
                    if past_past_step_creditELPO <= 80:
                        B_j:float = dict_B_j[mode]["0 to 80"][0] + dict_B_j[mode]["0 to 80"][1] * past_past_step_creditELPO
                    elif past_past_step_creditELPO <= 150:
                        B_j:float = dict_B_j[mode]["80 to 150"][0] + dict_B_j[mode]["80 to 150"][1] * past_past_step_creditELPO
                    else:
                        B_j:float = dict_B_j[mode]["150"][0] + dict_B_j[mode]["150"][1] * past_past_step_creditELPO
            else:
                B_j:float = 0
                
            A_i:float = 0

        new_creditK:float = past_past_step_creditELPO - A_i / 24 + B_j / 24
        
        credit_k.append(new_creditK)

    return credit_k