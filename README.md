# Housing-price-regression
Hedonic pricing model of 535 house sales (2020 to 2025) using a log-log OLS regression in Stata. Covers EDA, diagnostic testing (RESET, Breusch-Pagan, White, VIF, Cook’s D), price prediction intervals and a net-proceeds recommendation on which agent to sell through.
Junction Housing Price Analysis – Regression Model

A statistical analysis of 535 residential property sales in Junction between 2020 and 2025. It builds a regression model to predict sale prices and advise a homeowner (Jenny) on what her house should sell for and which agent to use.

Business question
What will Jenny’s house sell for, how much does each extra square metre add, and which agent leaves her with more money after commission?

Data summary
535 sales across 13 variables: price, size, age, distance to town, suburb, agent, ocean view, pool, tennis court, crime and shops
Two outliers removed: a $25,000 sale (likely a data entry error) and a $3.4m sale (extreme value), leaving n = 533
Mean price $412,574, median $407,188 (mild right skew)
Size is the strongest continuous predictor (r = 0.81 with price)
Data issues found
SHOPS is listed as binary in the data dictionary but takes values 0 to 3
CRIME and TOWN are perfectly collinear (r = 1.0), so only TOWN was kept
TOWN only takes two values (30km and 60km)
Headline model
ln(PRICE) = β0 + β1 ln(SIZE) + β2 OCEAN + β3 POOL + β4 TENNIS + β5 AGENT + β6 TOWN + ε
R² = 0.857, with all six predictors significant at 5%
Size elasticity: 0.77, so a 1% larger house sells for about 0.77% more
Ocean view premium: about 16.2%
Estimated with heteroskedasticity-robust standard errors
Diagnostics
Ramsey RESET: F = 1.26, p = 0.287, so no evidence of misspecification
Breusch-Pagan (p = 0.004) and White (p < 0.001): heteroskedasticity detected and corrected with robust SEs
VIF: mean 1.02, so no multicollinearity
Shapiro-Wilk: p = 0.265, so residuals are approximately normal
Cook’s distance and leverage: influential observations reviewed and kept
Results for Jenny

Predicted sale price: $517,878
95% prediction interval: $464,262 to $577,685
Value of each extra m²: about $2,436
Net proceeds via A&B (3.5% commission): $511,542
Net proceeds via W&M (2.8% commission): $503,377
Recommendation: sell through A&B, about $8,165 more after commission

Limitations

Jenny’s house is 10km from town, outside the 30 to 60km range in the data, so the prediction is an extrapolation
Jenny asked for an R² of 89%. Adding variables to reach it caused insignificance or multicollinearity, so the simpler, well-specified model was kept

Tools
Stata (regress, vce(robust), estat ovtest, estat hettest, estat imtest, vif, swilk)
