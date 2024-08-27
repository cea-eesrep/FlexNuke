#include <cstdio>
#include <vector>
#include <map>
#include <string>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

/**
 * Returns the corrected dataframe of crédit K after conservative horizon optimization.
*/
std::vector<float> credit_K_interprocessing_cpp(std::string mode, 
                                                    float pmax,
                                                    float efficiency,
                                                    float fuel_weight,
                                                    std::vector<float> elpo, 
                                                    std::vector<bool> is_elpo, 
                                                    std::vector<bool> is_po, 
                                                    std::vector<float> elec, 
                                                    std::vector<float> fpd, 
                                                    std::map<std::string, float> dict_K0,
                                                    std::map<std::string, std::map<std::string, float>> dict_A_i,
                                                    std::map<std::string, std::map<std::string, std::vector<float>>> dict_B_j){
    
    std::vector<float> credit_k;
    float past_step_is_ELPO, past_past_step_creditELPO, past_step_power, past_step_fdf, past_step_burnup, A_i, B_j = 0, past_step_PO;
    float new_creditK = dict_K0[mode];

    for (uint past_step_index=0; past_step_index < elpo.size(); past_step_index++){
        past_step_is_ELPO = is_elpo[past_step_index];

        if (past_step_index == 0){
            past_past_step_creditELPO = dict_K0[mode];
        }
        else{
            past_past_step_creditELPO = new_creditK;
        }

        if (past_step_is_ELPO != 0){
            past_step_power = elec[past_step_index];
            past_step_fdf = fpd[past_step_index];
            past_step_burnup = (past_step_fdf * pmax / efficiency) / fuel_weight;

            if (past_step_burnup <= 2000){
                if (past_step_power < 0.85 * pmax)
                    A_i = dict_A_i["0 to 2000 MWj/t"]["27 %Pn to 85 %Pn"];
                else
                    A_i = dict_A_i["0 to 2000 MWj/t"]["85 %Pn to 92 %Pn"];
            }
            else if (past_step_burnup <= 6000){
                if (past_step_power < 0.85 * pmax)
                    A_i = dict_A_i["2000 to 6000 MWj/t"]["27 %Pn to 85 %Pn"];
                else
                    A_i = dict_A_i["2000 to 6000 MWj/t"]["85 %Pn to 92 %Pn"];
            }
            else{
                if (past_step_power < 0.5 * pmax)
                    A_i = dict_A_i["6000 MWj/t to end"]["27 %Pn to 50 %Pn"];
                else
                    A_i = dict_A_i["6000 MWj/t to end"]["50 %Pn to 92 %Pn"];
            }

            B_j = 0;
        }
        else{
            past_step_PO = is_po[past_step_index];

            if (past_step_PO){
                if (mode == "Base"){
                    if (past_past_step_creditELPO <= 100)
                        B_j = dict_B_j[mode]["0 to 100"][0] + dict_B_j[mode]["0 to 100"][1] * past_past_step_creditELPO;
                    else if (past_past_step_creditELPO <= 199)
                        B_j = dict_B_j[mode]["100 to 200"][0] + dict_B_j[mode]["100 to 200"][1] * past_past_step_creditELPO;
                    else
                        B_j = dict_B_j[mode]["200"][0] + dict_B_j[mode]["200"][1] * past_past_step_creditELPO;
                }
                else if (mode == "Load-following"){
                    if (past_past_step_creditELPO <= 80)
                        B_j = dict_B_j[mode]["0 to 80"][0] + dict_B_j[mode]["0 to 80"][1] * past_past_step_creditELPO;
                    else if (past_past_step_creditELPO <= 150)
                        B_j = dict_B_j[mode]["80 to 150"][0] + dict_B_j[mode]["80 to 150"][1] * past_past_step_creditELPO;
                    else
                        B_j = dict_B_j[mode]["150"][0] + dict_B_j[mode]["150"][1] * past_past_step_creditELPO;
                }
            }
            else
                B_j = 0;
                
            A_i = 0;
        }

        new_creditK = past_past_step_creditELPO - A_i / 24 + B_j / 24;
        
        credit_k.push_back(new_creditK);
    }

    return credit_k;
}


PYBIND11_MODULE(post_processor, m) {
    m.doc() = "post_processor."; // optional module docstring

    m.def("credit_K_interprocessing_cpp",&credit_K_interprocessing_cpp, "post_process credit K");
}