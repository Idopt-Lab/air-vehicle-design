Written by Casey Chamberlain
8/14/2026

```mermaid
flowchart LR


subgraph GEOML1["GEOML1 TOOLBOX"]
    subgraph PROPERTIES_G1["PROPERTIES"]
        direction LR
        NONE["NONE"]
    end
    subgraph METHODS_STATIC_G1["METHODS (STATIC)"]
        direction LR
        GET_S_WET_STATISTICAL["GET_S_WET_STATISTICAL"]
        GET_L_FUS
        GET_AR_EQ
        GET_CONTROL_SURFACE_FRACTION
        COMPUTE_S_WET_REGRESSION
        COMPUTE_L_FUS_REGRESSION
        LOOKUP_S_WET
        LOOKUP_LFUS
        COMPUTE_AR_EQ
        LOOKUP_AR_EQ
        COMPUTE_CONTROL_SURFACE_FRACTION
        LOOKUP_CONTROL_SURFACE_FRACTION
    
    end
    subgraph METHODS_PRIVATE_G1["METHODS (STATIC, ACCESS = PRIVATE)"]
        direction LR
        none
    end
end

subgraph F16AGEOML1

    subgraph METHODS_PRIVATE_F16["methods (Access = private)"]
        direction LR
        requireWTO
    end
    
    subgraph METHODS_F16["methods"]
        direction LR
        F16GEOML1
        get_S_ref
        get_S_wet
        get_S_wet_statistical
        get_L_fus
        get_AR_eq
    end
end

subgraph INPUT1["F-16A input (L1) json"]
    direction LR
    aircraft_category
    subgraph geometry["geometry (NONE)"]
        direction LR
        n_engines
    end

    subgraph aerodynamics
        direction LR
        airfoil_type
        AR
        Lambda_LE_deg
        cd0_curve
    end

    subgraph propulsion
        direction LR
        engine_type
        T_SL
    end

    subgraph weights
        direction LR
        W_payload_fixed
        W_payload_expendable
    end
    subgraph subsystems
        subgraph fuel
            direction LR
            fuel_type
            fuel_density
        end

        subgraph avionics
            direction LR
            aircraft_category
            weight_fraction
            density_per_ft3
        end
    end
end

aircraft_category-->|"aircraft_category"|get_S_wet_statistical
```