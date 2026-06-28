create database TEMU_MARKETING_STRATERGY;
select* from competitors;
select* from temu_ad_spend;
select* from temu_growth;


-- TEMU BUSINESS STRATEGY ANALYSIS
-- SQL EXPLORATORY DATA ANALYSIS
-- SECTION 1 — FIRST LOOK
-- How many quarters of data do we have?
SELECT
    COUNT(*)     AS total_quarters,
    MIN(Quarter) AS first_quarter,
    MAX(Quarter) AS last_quarter
FROM temu_growth;

-- 1. Any missing values we need to worry about?
SELECT
    SUM(CASE WHEN GMV_USD_Billion       IS NULL THEN 1 ELSE 0 END) AS missing_gmv,
    SUM(CASE WHEN MAU_Millions          IS NULL THEN 1 ELSE 0 END) AS missing_mau,
    SUM(CASE WHEN Ad_Spend_USD_Billion  IS NULL THEN 1 ELSE 0 END) AS missing_adspend,
    SUM(CASE WHEN Avg_Order_Value_USD   IS NULL THEN 1 ELSE 0 END) AS missing_order_value
FROM temu_growth;



-- SECTION 2 — GMV AND REVENUE GROWTH
-- Key question: How fast did Temu actually grow?


-- 2. GMV every quarter with growth label
SELECT
    Quarter,
    GMV_USD_Billion,
    GMV_Growth_Pct,
    CASE
        WHEN GMV_Growth_Pct > 100 THEN 'EXPLOSIVE (100%+ growth)'
        WHEN GMV_Growth_Pct > 50  THEN 'STRONG (50-100% growth)'
        WHEN GMV_Growth_Pct > 0   THEN 'GROWING (0-50% growth)'
        WHEN GMV_Growth_Pct < 0   THEN 'DECLINING'
        ELSE 'BASELINE'
    END AS growth_label
FROM temu_growth
ORDER BY Quarter;


-- 2. Total GMV across all quarters combined
-- Context: Amazon does $750B per year. Temu hit $70.8B in year 3.
SELECT
    ROUND(SUM(GMV_USD_Billion), 2)    AS total_gmv_all_quarters,
    ROUND(AVG(GMV_USD_Billion), 2)    AS avg_gmv_per_quarter,
    ROUND(MIN(GMV_USD_Billion), 3)    AS lowest_quarter_gmv,
    ROUND(MAX(GMV_USD_Billion), 2)    AS highest_quarter_gmv,
    ROUND(MAX(GMV_USD_Billion) /
          MIN(GMV_USD_Billion), 0)    AS gmv_multiplier
FROM temu_growth;


-- 2. How much did average order value grow?
-- FINDING: Order value grew from $24 to $46
-- Means customers started spending slightly more per visit
-- But growth was still mostly from volume not value per order
SELECT
    Quarter,
    Avg_Order_Value_USD,
    ROUND(Avg_Order_Value_USD - LAG(Avg_Order_Value_USD)
          OVER (ORDER BY Quarter), 2) AS order_value_change
FROM temu_growth
ORDER BY Quarter;


-- 2d. What happened to GMV before and after the tariff shock?
-- Compare 2025 quarters vs 2024 quarters
SELECT
    CASE
        WHEN Quarter LIKE '%2022%' THEN '2022 Launch'
        WHEN Quarter LIKE '%2023%' THEN '2023 Explosion'
        WHEN Quarter LIKE '%2024%' THEN '2024 Scale'
        WHEN Quarter LIKE '%2025%' THEN '2025 Tariff Era'
    END AS era,
    COUNT(*)                         AS quarters,
    ROUND(AVG(GMV_USD_Billion), 2)   AS avg_quarterly_gmv,
    ROUND(SUM(GMV_USD_Billion), 2)   AS total_gmv
FROM temu_growth
GROUP BY
    CASE
        WHEN Quarter LIKE '%2022%' THEN '2022 Launch'
        WHEN Quarter LIKE '%2023%' THEN '2023 Explosion'
        WHEN Quarter LIKE '%2024%' THEN '2024 Scale'
        WHEN Quarter LIKE '%2025%' THEN '2025 Tariff Era'
    END
ORDER BY MIN(Quarter);



-- SECTION 3 — USER GROWTH ANALYSIS
-- Key question: Were users actually engaged or just downloading?
-- 3. MAU growth every quarter
SELECT
    Quarter,
    MAU_Millions,
    Cumulative_Downloads_Millions,
    -- How many downloads does it take to get one active user?
    -- Lower ratio = better quality downloads
    ROUND(Cumulative_Downloads_Millions / MAU_Millions, 2)
        AS downloads_per_active_user
FROM temu_growth
ORDER BY Quarter;


-- 3. User growth peak vs tariff shock drop
-- FINDING: MAU dropped from 292M to 260M after US tariff shock
-- That is a 32M user loss — bigger than most apps entire user base
SELECT
    Quarter,
    MAU_Millions,
    ROUND(MAU_Millions - LAG(MAU_Millions)
          OVER (ORDER BY Quarter), 1) AS mau_change_millions
FROM temu_growth
ORDER BY mau_change_millions ASC
LIMIT 5;


-- 3. Best and worst quarters for user growth
SELECT
    Quarter,
    MAU_Millions,
    ROUND(MAU_Millions - LAG(MAU_Millions)
          OVER (ORDER BY Quarter), 1) AS users_added_millions
FROM temu_growth
ORDER BY users_added_millions DESC;



-- SECTION 4 — THE PROFITABILITY QUESTION
-- Key question: Is Temu actually making money or buying growth?
-- This is the most important section in the entire analysis
-- 4. Revenue per user vs ad cost per user — the core tension
-- FINDING: In early quarters ad cost per user EXCEEDED
-- revenue per user — meaning Temu paid more to get each user
-- than that user generated in revenue
SELECT
    Quarter,
    Revenue_Per_User_USD,
    Ad_Cost_Per_User_USD,
    Net_Value_Per_User_USD,
    CASE
        WHEN Net_Value_Per_User_USD > 0
            THEN 'PROFITABLE per user'
        ELSE
            'LOSING MONEY per user'
    END AS profitability_status
FROM temu_growth
ORDER BY Quarter;


-- 4. How many quarters were profitable per user vs loss-making?
SELECT
    CASE
        WHEN Net_Value_Per_User_USD > 0
            THEN 'Profitable per user'
        ELSE 'Loss making per user'
    END AS user_economics,
    COUNT(*) AS number_of_quarters
FROM temu_growth
GROUP BY
    CASE
        WHEN Net_Value_Per_User_USD > 0
            THEN 'Profitable per user'
        ELSE 'Loss making per user'
    END;


-- 4. Revenue efficiency — GMV earned per dollar spent on ads
-- Higher = more efficient. Lower = burning cash.
-- FINDING: Efficiency collapsed in Q1 2025 when ads were halted
-- but GMV also dropped — proving ads were driving revenue
SELECT
    Quarter,
    GMV_USD_Billion,
    Ad_Spend_USD_Billion,
    ROUND(GMV_USD_Billion / Ad_Spend_USD_Billion, 2)
        AS gmv_per_ad_dollar,
    CASE
        WHEN GMV_USD_Billion / Ad_Spend_USD_Billion > 10
            THEN 'HIGHLY EFFICIENT'
        WHEN GMV_USD_Billion / Ad_Spend_USD_Billion > 5
            THEN 'EFFICIENT'
        WHEN GMV_USD_Billion / Ad_Spend_USD_Billion > 2
            THEN 'MODERATE'
        ELSE 'BURNING CASH'
    END AS ad_efficiency
FROM temu_growth
ORDER BY gmv_per_ad_dollar DESC;


-- 4d. Estimated total losses across all quarters
-- $30 loss per order, avg order $38.90 = 77% loss ratio
SELECT
    Quarter,
    GMV_USD_Billion,
    Estimated_Loss_USD_Billion,
    ROUND(Estimated_Loss_USD_Billion / GMV_USD_Billion * 100, 1)
        AS loss_as_pct_of_revenue
FROM temu_growth
ORDER BY Quarter;

-- What is the total estimated loss across ALL quarters combined?
SELECT
    ROUND(SUM(Estimated_Loss_USD_Billion), 2) AS total_estimated_losses,
    ROUND(SUM(GMV_USD_Billion), 2)            AS total_revenue,
    ROUND(SUM(Estimated_Loss_USD_Billion) /
          SUM(GMV_USD_Billion) * 100, 1)      AS overall_loss_ratio_pct
FROM temu_growth;



-- SECTION 5 — AD SPEND STRATEGY
-- Key question: When did they pivot from US to Europe?
-- 5a. US vs EU ad spend side by side
SELECT
    Period,
    US_Ad_Spend_USD_Billion,
    EU_Ad_Spend_USD_Billion,
    Total_USD_Billion,
    EU_as_Pct_of_US,
    CASE
        WHEN EU_as_Pct_of_US > 100
            THEN 'EU DOMINANT - Pivot complete'
        WHEN EU_as_Pct_of_US > 50
            THEN 'EU GROWING - Pivot underway'
        WHEN EU_as_Pct_of_US > 20
            THEN 'EU MINOR - US still dominant'
        ELSE 'US ONLY'
    END AS pivot_status
FROM temu_ad_spend
ORDER BY Period;


-- 5b. Which channel got the most money? Meta vs Google
SELECT
    Period,
    Meta_Spend_USD_Billion,
    Google_Spend_USD_Billion,
    CASE
        WHEN Google_Spend_USD_Billion = 0
            THEN 'Google ads halted'
        WHEN Meta_Spend_USD_Billion > Google_Spend_USD_Billion
            THEN 'Meta dominant'
        ELSE 'Google dominant'
    END AS dominant_channel
FROM temu_ad_spend
ORDER BY Period;


-- 5c. Total ad spend across entire period
SELECT
    ROUND(SUM(Total_USD_Billion), 2)   AS total_ad_spend_all_time,
    ROUND(SUM(US_Ad_Spend_USD_Billion), 2) AS total_us_spend,
    ROUND(SUM(EU_Ad_Spend_USD_Billion), 2) AS total_eu_spend,
    ROUND(SUM(Meta_Spend_USD_Billion), 2)  AS total_meta_spend,
    ROUND(SUM(Google_Spend_USD_Billion), 2) AS total_google_spend
FROM temu_ad_spend;

-- SECTION 6 — COMPETITIVE ANALYSIS
-- Key question: How does Temu actually compare to rivals?
-- 6a. Revenue comparison 2023 vs 2024 — who grew fastest?
SELECT
    Company,
    Revenue_2023_USD_Billion,
    Revenue_2024_USD_Billion,
    Revenue_Growth_Pct,
    RANK() OVER (ORDER BY Revenue_Growth_Pct DESC)
        AS growth_rank
FROM competitors
ORDER BY Revenue_Growth_Pct DESC;


-- 6b. Revenue per user — who monetizes best?
-- FINDING: Amazon makes ~$2,500 per user per year
-- Temu makes ~$253 per user per year
-- Temu needs 10x more users to match Amazon's revenue per user
SELECT
    Company,
    MAU_2024_Millions,
    Revenue_2024_USD_Billion,
    Annual_Revenue_Per_User_USD,
    Avg_Order_Value_USD,
    Loss_Per_Order_USD,
    RANK() OVER (ORDER BY Annual_Revenue_Per_User_USD DESC)
        AS monetization_rank
FROM competitors
ORDER BY Annual_Revenue_Per_User_USD DESC;


-- 6c. Profitability comparison
-- Who is actually making money?
SELECT
    Company,
    Loss_Per_Order_USD,
    CASE
        WHEN Loss_Per_Order_USD = 'Profitable'
            THEN 'Making money'
        WHEN CAST(REPLACE(Loss_Per_Order_USD, '-', '')
             AS DECIMAL(10,2)) > 20
            THEN 'Heavily loss-making'
        ELSE 'Moderately loss-making'
    END AS profit_status,
    Revenue_2024_USD_Billion
FROM competitors
ORDER BY Revenue_2024_USD_Billion DESC;


-- 6d. Market share estimate in discount e-commerce
-- Based on revenue among the four players in our table
SELECT
    Company,
    Revenue_2024_USD_Billion,
    ROUND(Revenue_2024_USD_Billion /
          SUM(Revenue_2024_USD_Billion) OVER () * 100, 1)
        AS market_share_pct
FROM competitors
ORDER BY Revenue_2024_USD_Billion DESC;



-- SECTION 7 — FINAL SUMMARY
-- The big picture queries that tell the whole story
-- 7a. The single most important query in this analysis
-- Did Temu's unit economics improve over time?
-- Are they getting closer to profitability per user?
SELECT
    Quarter,
    Net_Value_Per_User_USD,
    LAG(Net_Value_Per_User_USD)
        OVER (ORDER BY Quarter) AS prev_quarter,
    ROUND(Net_Value_Per_User_USD -
          LAG(Net_Value_Per_User_USD)
          OVER (ORDER BY Quarter), 2) AS improvement,
    CASE
        WHEN Net_Value_Per_User_USD >
             LAG(Net_Value_Per_User_USD)
             OVER (ORDER BY Quarter)
            THEN 'IMPROVING'
        ELSE 'WORSENING'
    END AS trajectory
FROM temu_growth
ORDER BY Quarter;


-- 7b. Era summary — how did each phase of Temu's life compare?
SELECT
    CASE
        WHEN Quarter LIKE '%2022%' THEN '1 - Launch (2022)'
        WHEN Quarter LIKE '%2023%' THEN '2 - Explosion (2023)'
        WHEN Quarter LIKE '%2024%' THEN '3 - Scale (2024)'
        WHEN Quarter LIKE '%2025%' THEN '4 - Tariff Era (2025)'
    END AS business_era,
    ROUND(AVG(GMV_USD_Billion), 2)          AS avg_quarterly_gmv,
    ROUND(AVG(MAU_Millions), 1)             AS avg_mau,
    ROUND(AVG(Ad_Spend_USD_Billion), 2)     AS avg_ad_spend,
    ROUND(AVG(Revenue_Per_User_USD), 2)     AS avg_rev_per_user,
    ROUND(AVG(Net_Value_Per_User_USD), 2)   AS avg_net_per_user
FROM temu_growth
GROUP BY
    CASE
        WHEN Quarter LIKE '%2022%' THEN '1 - Launch (2022)'
        WHEN Quarter LIKE '%2023%' THEN '2 - Explosion (2023)'
        WHEN Quarter LIKE '%2024%' THEN '3 - Scale (2024)'
        WHEN Quarter LIKE '%2025%' THEN '4 - Tariff Era (2025)'
    END
ORDER BY business_era;



-- THE CONCLUSION THIS DATA TELLS:

-- Temu grew from $275M to $70.8B in revenue in 3 years —
-- the fastest e-commerce growth in history.
-- But they lost an estimated $30 on every single order placed.
-- Their entire strategy was: lose money now, dominate later.
-- The US tariff shock in 2025 removed their biggest market
-- and exposed whether the model works without subsidised growth.
-- The EU pivot is now the real test — if European users show
-- better retention than US users, the business survives.
-- If they churn the same way, Temu is Wish with better marketing.
