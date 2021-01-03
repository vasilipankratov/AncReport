# Display Plan
**1.** Barplot showing the percent of distant (degree = -1) relatives among national groups (Estonians, Finns, Russians, etc). 
Three bars per each donor group: you, average within this donor groups, average for the group with the most similar copying vector. 
The latter can be changed to the self-reported group.

**2.** Barplot showing the percent of distant relatives within Estonians from different maakonds.
Three bars per each donor group: you, average within this donor groups, average for the group with the most similar copying vector. 
The latter can be changed to the self-reported group.

**3.** A map with close relatives: Estonian relatives of degrees 7 and 6 are pooled together by maakond and shown by the size and colour of the Maakond. 
Estonians closer than 6th degree up to the degree which is ethical together with relatives from other ethnic groups are shown by symbols on the map. 
The symbol shows the relatedness degree and ethnicity of the relative by symbol type and color while it's position on the map shows where the relative comes from.
Perhaps a pannel beneath the map would be needed to show relatives with unknown geographic origin.

# Files description
The test.txt file contains a sample result of a query from the database for an individual with a v-code VXXXXX
This is used as input for the R script
Intilly there is no header but in R the columns are named as follows 
'total','maakond','nation','maakond1','nation1', 'count', 'degree'
and each line shows the number of Biobank Donors (count) of a given nationaluty (nation) from a given maakond (maakond) 
that are your relatives of a goven degree (degree). The total (total) is showing how many donors in each nation-maakond group there are in hte Biobank.
For example, line 23 of the test files says that out of 29524 Estonian from Hajumaa in the Biobank 5 are your 4th degree relatives.

The DonorFeedbackBackground_v2.Rdata file contains background info to compare the individual in focus to some average values (like average for nations and for Estonians from different maakonds).

The R script basically aggregates this data by a) degree of relatedness, b) nationality, c) maakonds for Estonians and Russians.This creates a list of 6 dataframes:
(nationalities, Estonians by maakonds, Russians by maakonds) x (distant and close relatives). The counts are also normalized by the total number of donors in each give group. Then the individual data are combined with average Joes for comparison. This results in matrices of the following type

$Nations.dist

Donor    | Eestlane | Juut | Latlane | Leedulane
--------------|----------|------|---------|----------
you | 13.68 | 2.86 | 10.71 | 5.19
Juut | 3.93 | 40.31| 4.03  | 4.10
Latlane | 11.98 | 4.25 | 17.84 | 9.26
Leedulane | 7.53 | 3.83 | 8.79 | 10.48

with each value showing the precent of donors in each group that are your relatives (either distant or close). 
In R I transform it to long format for plotting with ggplot then but basically the matrix is what should be plotted.

We also plan to use values of sharing with Estonians in different maakond like below to plot those on the map but this code is developed by another person and I don't have it at the moment. As these maps (see below) are rather fancy I wonder if it would be possible to do it outside R.

$Est.dist
Donor | Est_Harju | Est_Hiiu | Est_Ida-Viru | Est_Jarva |
------|-----------|----------|--------------|-----------|
you | 14.95 | 12.3 | 13.38 | 13.12 |

![map](https://github.com/vasilipankratov/AncReport/blob/main/001_HarjuEst.png)

The Matrixx_VXXXXX_Eestlane_Harju_1943.pdf file contains a sample output of the R script.

#Update 03.01.2021
Added a file Barplot_VXXXXX_Eestlane_Harju_1943.pdf with the same info as in Matrixx_VXXXXX_Eestlane_Harju_1943.pdf but presented as barplot and an updated R script that produces this file.

