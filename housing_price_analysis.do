*******************************************************************************
* Junction Housing Price Analysis - Hedonic Regression Model
* Author: Mervyn Regeo Varghese
* Software: Stata 18
*
* Purpose: Predict the sale price of Jenny's house and recommend a selling
*          agent, using 535 residential sales in Junction (2020-2025).
*
* Data: "Major Project - Data Set.xlsx" (place in the same folder as this file)
* Variables: OBS AGE SHOPS CRIME TOWN STORIES OCEAN POOL PRICE AGENT SIZE
*            SUBURB TENNIS SOLD
*******************************************************************************

clear all
set more off
capture log close
log using "housing_price_analysis.log", replace text


*==============================================================================
* 0. LOAD DATA
*==============================================================================
import excel "Major Project - Data Set.xlsx", sheet("Sheet1") firstrow clear
describe


*==============================================================================
* 1. DATA CLEANING - remove two outliers
*==============================================================================
* OBS 362: PRICE = $25,000    -> implausibly low, likely data entry error
* OBS 400: PRICE = $3,402,000 -> extreme high-value outlier
list OBS PRICE SIZE if OBS == 362 | OBS == 400
drop if OBS == 362 | OBS == 400
count        // expect 533


*==============================================================================
* 2. TASK 1 - DATA SUMMARY
*==============================================================================

* 2.1 Summary statistics for continuous variables
tabstat PRICE SIZE AGE TOWN, statistics(n mean median sd min max) ///
    columns(statistics) format(%12.2f)

* 2.2 Frequency tables for categorical variables
foreach v in SUBURB AGENT OCEAN POOL TENNIS STORIES {
    tab `v'
}

* 2.3 Data peculiarities
tab SHOPS                 // defined as binary but takes values 0-3
tab CRIME                 // takes only values 1 and 3
tab TOWN                  // takes only values 30 and 60
correlate CRIME TOWN      // perfectly collinear (r = 1)

* 2.4 Graphs
histogram PRICE, frequency normal ///
    title("Figure 1: Distribution of Sale Price") xtitle("Sale price ($)")
graph export "fig1_price_hist.png", replace

histogram SIZE, frequency normal ///
    title("Figure 2: Distribution of House Size") xtitle("Size (m2)")
graph export "fig2_size_hist.png", replace

graph bar (count), over(SOLD) ///
    title("Figure 3: Houses Sold by Year") ytitle("Number of sales")
graph export "fig3_sales_by_year.png", replace

graph box PRICE, over(OCEAN) over(SUBURB) ///
    title("Figure 4: Sale Price by Suburb and Ocean View")
graph export "fig4_price_box.png", replace

twoway (scatter PRICE SIZE) (lfit PRICE SIZE), ///
    title("Figure 5: Sale Price vs House Size") ///
    xtitle("Size (m2)") ytitle("Sale price ($)") legend(off)
graph export "fig5_price_vs_size.png", replace
correlate PRICE SIZE      // r = 0.81


*==============================================================================
* 3. TASK 2 - REGRESSION MODEL
*==============================================================================

* 3.1 Log transformations
gen lnPRICE = ln(PRICE)
gen lnSIZE  = ln(SIZE)

* 3.2 Full model (all available predictors)
* CRIME is dropped automatically because it is perfectly collinear with TOWN
regress lnPRICE lnSIZE AGE SHOPS CRIME TOWN STORIES OCEAN POOL ///
    AGENT SUBURB TENNIS

* 3.3 Headline model (OLS) - used for diagnostics
regress lnPRICE lnSIZE OCEAN POOL TENNIS AGENT TOWN
estimates store ols


*==============================================================================
* 4. TASK 3 - MODEL EVALUATION (on OLS fit)
*==============================================================================

* 4.1 Functional form - Ramsey RESET test
estat ovtest              // F(3,523) = 1.26, p = 0.287

* 4.2 Heteroskedasticity
estat hettest             // Breusch-Pagan: chi2(1) = 8.13, p = 0.004
estat imtest, white       // White: chi2(22) = 83.86, p = 0.000

* 4.3 Multicollinearity
vif                       // mean VIF = 1.02

* 4.4 Residual diagnostics
predict yhat, xb
predict resid, residuals
rvfplot, yline(0) title("Residuals vs Fitted Values")
graph export "fig6_rvf.png", replace

histogram resid, normal title("Distribution of Residuals")
graph export "fig7_resid_hist.png", replace

qnorm resid, title("Normal Q-Q Plot of Residuals")
graph export "fig8_qq.png", replace

swilk resid               // W = 0.996, p = 0.265

* 4.5 Influential observations
predict cooksd, cooksd
predict lev, leverage
local n = e(N)
local k = e(df_m)
list OBS PRICE SIZE cooksd if cooksd > 4/`n' & !missing(cooksd)
list OBS PRICE SIZE lev    if lev > 2*(`k'+1)/`n' & !missing(lev)


*==============================================================================
* 5. HEADLINE MODEL - heteroskedasticity-robust standard errors
*==============================================================================
regress lnPRICE lnSIZE OCEAN POOL TENNIS AGENT TOWN, vce(robust)
estimates store robust
* R2 = 0.857, all six predictors significant at 5%


*==============================================================================
* 6. PREDICTIONS FOR JENNY
*==============================================================================
* Jenny's house: 164 m2, ocean view, pool, tennis court, TOWN = 10 km
* TOWN = 10 is outside the observed range (30-60), so TOWN = 30 is used
* (closest observed value - this is an extrapolation)

local n0 = _N
set obs `=`n0' + 2'
local wm = `n0' + 1       // row for agent W&M (AGENT = 0)
local ab = `n0' + 2       // row for agent A&B (AGENT = 1)

replace lnSIZE = ln(164) in `wm'/`ab'
replace OCEAN  = 1       in `wm'/`ab'
replace POOL   = 1       in `wm'/`ab'
replace TENNIS = 1       in `wm'/`ab'
replace TOWN   = 30      in `wm'/`ab'
replace AGENT  = 0       in `wm'
replace AGENT  = 1       in `ab'

predict lnp_hat in `wm'/`ab', xb
predict se_f    in `wm'/`ab', stdf

local tcrit = invttail(e(df_r), 0.025)

* Q1 - Point prediction (W&M)
local p_wm = exp(lnp_hat[`wm'])
display "Q1 Point prediction (W&M): $" %12.0fc `p_wm'

* Q2 - 95% prediction interval (W&M)
local lo = exp(lnp_hat[`wm'] - `tcrit'*se_f[`wm'])
local hi = exp(lnp_hat[`wm'] + `tcrit'*se_f[`wm'])
display "Q2 95% PI: $" %12.0fc `lo' "  to  $" %12.0fc `hi'

* Q3 - Marginal effect of one extra m2
local me = _b[lnSIZE] * `p_wm' / 164
display "Q3 Marginal effect of 1 m2: $" %8.0fc `me'

* Q4 - Agent recommendation (net of commission)
local p_ab   = exp(lnp_hat[`ab'])
local net_wm = `p_wm' * (1 - 0.028)     // W&M commission 2.8%
local net_ab = `p_ab' * (1 - 0.035)     // A&B commission 3.5%
display "Gross: W&M $" %12.0fc `p_wm' "   A&B $" %12.0fc `p_ab'
display "Net:   W&M $" %12.0fc `net_wm' "   A&B $" %12.0fc `net_ab'
display "Difference (A&B - W&M): $" %10.0fc `net_ab' - `net_wm'

* Remove the prediction rows
drop in `wm'/`ab'


log close
*******************************************************************************
* END
*******************************************************************************
