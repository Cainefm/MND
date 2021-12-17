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
- Protocol: [AESIs in COVID-19 Subjects Protocol](https://ohdsi-studies.github.io/Covid19SubjectsAesiIncidenceRate/Protocol.html)
- Publications: **-**
- Results explorer: **-**

# Requirements
- A database in the data shall format provided in protocol
- R version 4.0.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)

# How to Run
1. Install [R](https://www.r-project.org/) and/or [Rstudio](https://www.rstudio.com/products/rstudio/download/).

2. Insatll [RTools](https://cran.r-project.org/bin/windows/Rtools/rtools40.html)

3. Create an empty folder or new RStudio project. Then in R, use the following code to install the study package and its dependencies:

    ```r
    library("devtools")
    install_github("Cainefm/MND")
    ```

4. For incidence estimation. 

    ```r
     run_inci()
    ```

5. 
