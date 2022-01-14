## Epidemiology study of Motor neuron disease with the collaboration in the Neurogen
### Updated time: **2022-1-13**  


<img src="https://img.shields.io/badge/Project-Preparing-red.svg" alt="Study Status: Started">  

- Study type: **Epidemiology study**
- Tags: **Common data model**, **MND**
- Study sites:
  - **Hong Kong** : Celine Chui, FAN Min, Gao Le, Edmund Cheung
  - **Tai Wan** ：Edward Lai, Daniel Tsai
  - **Korea** ：Ju-Young Shin, Sungho Bea
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

3. Copy the [mnd_codes.xlsx](https://github.com/Cainefm/MND/blob/master/data/codes_mnd.xlsx) file into the local drive and input your regional values, eg. population.

    ![image](https://user-images.githubusercontent.com/20833144/147719924-4d872bcb-e6fa-400b-b0af-a255d0945035.png)

4. Create an empty folder or new RStudio project. Then in R, use the following code to install the study package and its dependencies:
    ```r
    install.packages("devtools") # may need to input 1 or 2 if there are any packages needed to update. 
    library("devtools")
    devtools::install_github("Cainefm/MND",upgrade="never")
    library("MND")
    dir_mnd_codes <- "" #pls input your directory of MND_codes.xlsx here. 
    ```

5. The common data shell are presented in the protocol

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
    ## A sub population in HK for testing are attached in the package
    demo
    ```
    <p align="center">
       <img width="400" src="https://user-images.githubusercontent.com/20833144/147063331-ce859a07-d71e-4c7e-9be4-4797d81764fa.png">
    </p>
    
6. For incidence estimation and time-varing cox regression.  

    ### Standardized incidence  

    ```r
    dt_desc <- run_desc(demo, dx, rx, ip, region = "hk", codes_sys = "icd9")
    # the standardized incidence
    dt_desc$std_inci
    # the raw data for incidence
    dt_desc$dt_raw
    ```  
    <p align="center">
        <img width="400" src="https://user-images.githubusercontent.com/20833144/147910480-231b626b-05e4-4098-aa68-0c6ab1884663.png">
    </p>


    ```r
    p_inci(dt_desc)
    ```
    <p align="center">
       <img width="600" src="https://user-images.githubusercontent.com/20833144/147521882-81b3577f-fff9-4df4-b2b3-fedacc59e181.png">
    </p>


    ```r
    p_inci_sex(dt_desc)
    ```
    <p align="center">
       <img width="700" src="https://user-images.githubusercontent.com/20833144/147545663-d858cd7b-fb99-46c6-9b9c-d43cc97bdf5d.png">
    </p>


    ```r
    p_inci_type(dt_desc)
    ```
    <p align="center">
       <img width="800" src="https://user-images.githubusercontent.com/20833144/147545748-22dea721-5b01-4e06-88ff-d2888f6650d3.png">
    </p>

    ### Time-varing Cox regression

    ```r
    dt_desc$cox_est
    ```
    <p align="center">
       <img width="300" src="https://user-images.githubusercontent.com/20833144/149447726-845ab9dd-a99c-4bfa-96af-441492e64c1c.png">
    </p>
    

7. Generate table one descriptive statistics
    ```r
    dt_desc$tableone
    ```
    <p align="center">
       <img width="800" src="https://user-images.githubusercontent.com/20833144/147919038-75ee9cb2-e986-4d2e-9f0c-35a67b5d46a9.png">
    </p>   

8. For sccs estimation:
    ```r
    run_sccs(demo, dx, rx, ip，
              riluzole_name = "riluzole|riluteck",
              obst = "2001-08-24",
              obed = "2018-12-31")
    ```
    <p align="center">
       <img width="300" src="https://user-images.githubusercontent.com/20833144/147911318-fcd2ec92-e391-400d-9bbf-df843d3ecf74.png">
    </p>
