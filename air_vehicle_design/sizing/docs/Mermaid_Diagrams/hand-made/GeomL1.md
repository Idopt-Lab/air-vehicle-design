Written by Casey Chamberlain
8/14/2026

```mermaid
flowchart TD

subgraph GEOML1["GEOML1 TOOLBOX"]
    subgraph PROPERTIES["PROPERTIES"]
        direction LR
        NONE["NONE"]
    end
    subgraph METHODS_STATIC["METHODS (STATIC)"]
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
    subgraph METHODS_PRIVATE["METHODS (STATIC, ACCESS = PRIVATE)"]
        direction LR
        none
    end
end
```