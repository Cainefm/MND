## Epidemiology study of Motor neuron disease with the collaboration in the Neurogen

=============

<img src="https://img.shields.io/badge/Project-Preparing-red.svg" alt="Study Status: Started">

- Study type: **Epidemiology study**
- Tags: **Common data model**, **MND**
- Study lead: *Celine Chui*, *FAN Min*
- Study sites: 
  - **Hong Kong** : *FAN Min*
  - **Tai Wan** ：**
  - **Korea** ：**[Ju-Young Shin](https://skb.skku.edu/eng_pharm/intro/faculty_pharmacy.do?mode=view&perId=LZStrIYVgqgzg6gKgdgTwMYFMCyBFAmkgnMAZQCk4AOAaQwF4qg%20&)**, **[Sungho Bea]()**
- Study start date: **Jun, 2021**
- Study end date: **-**
- Protocol: 
- Publications: **-**
- Results explorer: **-**

# Requirements
- A database in the data shall format provided in protocol
- R version 4.0.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)

# How to Run
1. Install [R](https://www.r-project.org/) and/or [Rstudio](https://www.rstudio.com/products/rstudio/download/).

2. Install [RTools](https://cran.r-project.org/bin/windows/Rtools/rtools40.html)

3. Create an empty folder or new RStudio project. Then in R, use the following code to install the study package and its dependencies:

    ```r
    library("devtools")
    install_github("Cainefm/MND")
    ```

4. The common data shell are presented in the protocol  

**Demographic table**  
![image](https://user-images.githubusercontent.com/20833144/147062700-bfa24423-680f-40da-a9f3-a58b5be34663.png)  
**Inpatient records**  
![image](https://user-images.githubusercontent.com/20833144/147062780-5cca43e7-7fa3-4c17-b534-6ba84e089fbf.png)  
**Drug records**  
![image](https://user-images.githubusercontent.com/20833144/147062866-eeccd191-d07c-41c0-baca-9f8b397e9331.png)  
**Diagnosis records**  
![image](https://user-images.githubusercontent.com/20833144/147062935-b6d7ab55-aee7-455e-bdf0-b9da26444542.png)  

*\* The reference date is the admission date in inpatient, outpatient, and A&E settings.*
*$The codes can be ICD 9, ICD 10 or read codes.*
 
6. For incidence estimation. 

    ```r
     run_inci()
    ```

5. For sccs estimation:
    ```r
     run_sccs()
    ```


