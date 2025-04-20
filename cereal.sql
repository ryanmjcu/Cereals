/* 
    Fields in the dataset:

    Name: Name of cereal
    mfr: Manufacturer of cereal
        A = American Home Food Products;
        G = General Mills
        K = Kelloggs
        N = Nabisco
        P = Post
        Q = Quaker Oats
        R = Ralston Purina
    type:
        cold
        hot
    calories: calories per serving
    protein: grams of protein
    fat: grams of fat
    sodium: milligrams of sodium
    fiber: grams of dietary fiber
    carbo: grams of complex carbohydrates
    sugars: grams of sugars
    potass: milligrams of potassium
    vitamins: vitamins and minerals - 0, 25, or 100, indicating the typical percentage of FDA recommended
    shelf: display shelf (1, 2, or 3, counting from the floor)
    weight: weight in ounces of one serving
    cups: number of cups in one serving
    rating: a rating of the cereals (Possibly from Consumer Reports?)
*/


-- Database already created in pgAdmin 4, so no need to CREATE DATABASE in code
-- CREATE the table
DROP TABLE IF EXISTS cereal;
CREATE TABLE cereal (
    name VARCHAR(255),
    mfr VARCHAR(255),
    type VARCHAR(255),
    calories DECIMAL,
    protein DECIMAL,
    fat DECIMAL,
    sodium DECIMAL,
    fiber DECIMAL,
    carbo DECIMAL,
    sugars DECIMAL,
    potass DECIMAL,
    vitamins DECIMAL,
    shelf INTEGER,
    weight DECIMAL,
    cups DECIMAL,
    rating DECIMAL
);

-- Import the dataset to the table
COPY cereal
FROM 'D:\SQL Projects\Cereals\cereal.csv' DELIMITER ',' CSV HEADER;

-- Check the data to make sure everything looks right
SELECT *
FROM cereal;

/* 
General characteristics of a few columns
*/

SELECT  
    MIN(sugars) AS lowest_sugar,
    MAX(sugars) AS highest_sugar,
    AVG(sugars) AS avg_sugars,
    MIN(calories) AS lowest_cals,
    MAX(calories) AS highest_cals,
    AVG(calories) AS avg_cals,
    MIN(fat) AS lowest_fat,
    MAX(fat) AS highest_fat,
    AVG(fat) AS avg_fat
FROM cereal;



/*
I see that some MIN values are -1, which isn't possible.
These must be representing missing or NULL values.
Given the already small dataset of 80 cereals, I'll replace those -1's with NULL, 
rather than dropping the rows entirely.
*/

UPDATE cereal
SET sugars = NULL
WHERE sugars = -1;



-- Now to find if any other -1, or otherwise impossible, values exist in the data
SELECT  
    MIN(calories) AS min_cals,
    MIN(protein) AS min_protein,
    MIN(fat) AS min_fat,
    MIN(sodium) AS min_sodium,
    MIN(fiber) AS min_fiber,
    MIN(carbo) AS min_carbs, -- has -1 minimum
    MIN(sugars) AS min_sugar,
    MIN(potass) AS min_potassium, -- has -1 minimum
    MIN(cups) AS min_serving_size,
    MIN(rating) AS min_rating
FROM cereal;



-- UPDATE the table to fix those values
UPDATE cereal
SET carbo = NULL
WHERE carbo = -1;

UPDATE cereal
SET potass = NULL
WHERE potass = -1;

SELECT  
    MIN(calories) AS min_cals,
    MIN(protein) AS min_protein,
    MIN(fat) AS min_fat,
    MIN(sodium) AS min_sodium,
    MIN(fiber) AS min_fiber,
    MIN(carbo) AS min_carbs, -- fixed!
    MIN(sugars) AS min_sugar,
    MIN(potass) AS min_potassium, -- fixed!
    MIN(rating) AS min_rating
FROM cereal;


/*
Get an overview of the data:
- average rating across all cereals 
- top 5 cereals by rating
- most common manufacturer
- ratings by mfr
*/

-- Average rating of all cereals
SELECT  
    ROUND(AVG(rating), 2) AS avg_rating
FROM cereal;



-- Top 5 by rating
SELECT
    name,
    rating
FROM cereal
ORDER BY rating DESC
LIMIT 5;



-- Most common manufacturer
SELECT  
    mfr,
    COUNT(*) AS product_count,
    ROUND((100.0 * COUNT(*) / (SELECT COUNT(*) FROM cereal)), 2) AS perc_of_cereals
FROM cereal
GROUP BY mfr
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Ratings by mfr
SELECT  
    mfr,
    ROUND(AVG(rating), 2) AS avg_rating
FROM cereal
GROUP BY mfr
ORDER BY avg_rating DESC;

/*
Shelving insights
- How do ratings vary by shelf?
- What shelves do the top 3 manufacturers stock their items on?
- What are the top 3 rated products by shelf?
*/

-- How do ratings vary by shelf?

SELECT  
    shelf,
    ROUND(AVG(rating),2) AS avg_rating
FROM cereal
GROUP BY shelf
ORDER BY shelf DESC;

-- Sugar content by shelf
SELECT
    shelf,
    ROUND(AVG(sugars), 2) AS avg_sugars
FROM cereal
GROUP BY shelf
ORDER BY shelf DESC;



-- What shelves do the top 3 manufacturers (by product count) stock their items on?
WITH top_mfrs AS (
    SELECT
        mfr,
        COUNT(*) AS product_count
    FROM cereal
    GROUP BY mfr
    ORDER BY product_count DESC
    LIMIT 3
)

SELECT
    mfr,
    shelf,
    COUNT(name) AS product_count
FROM cereal
WHERE mfr IN (SELECT mfr FROM top_mfrs)
GROUP BY mfr, shelf
ORDER BY mfr, shelf DESC, product_count DESC;



-- What are the top 3 rated products by shelf?
WITH products_ranked AS (
    SELECT 
        name,
        rating,
        shelf,
        RANK() OVER (PARTITION BY shelf ORDER BY rating DESC, SHELF DESC) AS rnk 
    FROM cereal
    GROUP BY name, rating, shelf
)

SELECT
    name,
    rating,
    shelf
FROM products_ranked
WHERE rnk <= 3



/* 
Nutrional insights
- Cereals with healthiest cal-to-serving size ratios
- Most filling cereal (high fiber and protein)
- Sugar levels and avg rating
*/

-- Cereals with best cal-to-serving size ratios
SELECT  
    name,
    ROUND(MIN(calories/cups), 2) AS cals_per_serving
FROM cereal
GROUP BY name
ORDER BY cals_per_serving
LIMIT 3;



-- Most filling cereals
SELECT
    name,
    cups,
    fiber,
    protein
FROM cereal
WHERE cups >= 1
ORDER BY fiber DESC, protein DESC
LIMIT 5;



-- Sugar content and rating
SELECT  
    CASE WHEN sugars <=5 THEN 'Low Sugar'
        WHEN sugars BETWEEN 6 AND 10 THEN 'Moderate Sugar' 
    ELSE 'Very Sugary' 
    END AS sugar_level,
    ROUND(AVG(rating), 2) AS avg_rating
FROM cereal
WHERE sugars IS NOT NULL
GROUP BY sugar_level
;


-- Are more sugary cereals sold in larger boxes?
SELECT  
    weight,
    ROUND(AVG(sugars), 2) AS avg_sugars
FROM cereal
GROUP BY weight
ORDER BY weight DESC;
    

-- 3 Most and 3 least calorically dense cereals

WITH high_cal_density AS (
    SELECT
        name,
        ROUND((calories/cups), 2) AS cal_density
    FROM cereal
    ORDER BY cal_density DESC
    LIMIT 3
),
low_cal_density AS (
    SELECT
        name,
        ROUND((calories/cups), 2) AS cal_density
    FROM cereal
    ORDER BY cal_density 
    LIMIT 3
)
SELECT
    name,
    cal_density AS cals_per_cup
FROM high_cal_density

UNION

SELECT 
    name, 
    cal_density AS cals_per_cup
FROM low_cal_density

ORDER BY cals_per_cup DESC
;

