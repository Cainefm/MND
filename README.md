## Epidemiology study of Motor neuron disease with the collaboration in the Neurogen


<img src="https://img.shields.io/badge/Project-Preparing-red.svg" alt="Study Status: Started">

- Study type: **Epidemiology study**
- Tags: **Common data model**, **MND**
- Study sites:
  - **Hong Kong** : **FAN Min**
  - **Tai Wan** ：**Edward Lai**，**Daniel Tsai**
  - **Korea** ：**Ju-Young Shin**, **Sungho Bea**
- Protocol: v1.2 
- Publications: **-**

# Requirements
- A database in the data shall format provided in protocol
- R version 4.0.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- **SCCS version has to be version 1.3. Now there is a potential bug in version 1.4 or above.**

# How to Run
1. Install [R](https://www.r-project.org/) and/or [Rstudio](https://www.rstudio.com/products/rstudio/download/).

2. Install [RTools](https://cran.r-project.org/bin/windows/Rtools/rtools40.html)

3. Create an empty folder or new RStudio project. Then in R, use the following code to install the study package and its dependencies:

    ```r
    library("devtools")
    install_github("Cainefm/MND")
    ```

4. The common data shell are presented in the protocol

****
  Demographic table
<p align="center">
  <img width="400" src="https://user-images.githubusercontent.com/20833144/147062700-bfa24423-680f-40da-a9f3-a58b5be34663.png">
</p>
  Inpatient records
<p align="center">
 <img width="300" src="https://user-images.githubusercontent.com/20833144/147062780-5cca43e7-7fa3-4c17-b534-6ba84e089fbf.png">
</p>
 Drug records
<p align="center">
 <img width="500" src="https://user-images.githubusercontent.com/20833144/147062866-eeccd191-d07c-41c0-baca-9f8b397e9331.png">
</p>
   Diagnosis records
<p align="center">
   <img width="400" src="https://user-images.githubusercontent.com/20833144/147062935-b6d7ab55-aee7-455e-bdf0-b9da26444542.png">
</p>

    ```r
    ## Some data for testing are attached in the package
    data(demo)
    ```
<p align="center">
   <img width="400" src="https://user-images.githubusercontent.com/20833144/147063331-ce859a07-d71e-4c7e-9be4-4797d81764fa.png">
</p>
6. For incidence estimation.

    ```r
    site_inci <- run_incidence(demo, dx, rx)
    # the standardized incidence
    site_inci$std_inci
    # the raw data for incidence
    site_inci$raw_dt
    ```

6.1 Figure plotting
    ```r
    p_inci(site_inci)
    ```
<p align="center">
   <img width="600" src="https://user-images.githubusercontent.com/20833144/147521882-81b3577f-fff9-4df4-b2b3-fedacc59e181.png">
</p>

    ```r
    p_inci_sex(site_inci)
    ```
<p align="center">
   <img width="700" src="https://user-images.githubusercontent.com/20833144/147545663-d858cd7b-fb99-46c6-9b9c-d43cc97bdf5d.png">
</p>


    ```r
    p_inci_type(site_inci)
    ```

<p align="center">
   <img width="800" src="https://user-images.githubusercontent.com/20833144/147545748-22dea721-5b01-4e06-88ff-d2888f6650d3.png">
</p>

5. For sccs estimation:
    ```r
    run_sccs(demo,rx,ip)
    ```

