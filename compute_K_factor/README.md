The function **credit_K_interprocessing** is called between every rolling horizon of the EESREP models. It takes the results of the past horizons, and recomputes the credit K in it. It takes the following arguments:

- results : Pandas dataframe in which the results of the past rolling horizon are read.
- flexible_units : List of FlexibleNPP in which are contained: name, p_max, efficiency, fuel_weight and ELPO_mode
- dict_K0 : Start credit K value based on the reactor piloting mode;
- dict_A_i : Credit K decrease coefficients
- dict_B_j : Credit K increase coefficients

When the nuclear units count or the past horizon is large, the credit K computation time can become significant. It can be greatly reduced using the cython version of the code. Cython is a "compiled version of python" which can get 100 times faster than python to compute the same thing.

Cython code can be compiled using the following command from the FlexNuke/compute_K_factor folder:

    python .\builder.py build_ext --inplace

If it is your first time compiling cython code, you will to pip install the python Cython module, 

    python -m pip install Cython

and to have a compiler installed on the computer, for example gcc on linux, and Microsoft visual C++ for windows:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170

A C++ version is also provided, it has similar performances to the Cython version.