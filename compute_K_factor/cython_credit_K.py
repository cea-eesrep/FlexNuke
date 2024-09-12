import pandas as pd
from typing import Dict, List

from .cython_credit_K_interprocessing import credit_K_interprocessing_cython_typed

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
        p_max = flexible_units[flexible_unit].p_max
        efficiency = flexible_units[flexible_unit].efficiency
        fuel_weight = flexible_units[flexible_unit].fuel_weight

        new_results[name+"_creditELPO"] = credit_K_interprocessing_cython_typed(mode, 
                                                                                p_max, 
                                                                                efficiency, 
                                                                                fuel_weight, 
                                                                                list(new_results[name+"_creditELPO"]), 
                                                                                list(new_results[name+"_is_step_ELPO"]), 
                                                                                list(new_results[name+"_PO"]), 
                                                                                list(new_results[name+"_electricity"]), 
                                                                                list(new_results[name+"_fpd"]), 
                                                                                dict_K0, 
                                                                                dict_A_i, 
                                                                                dict_B_j)
    # end for units

    return new_results