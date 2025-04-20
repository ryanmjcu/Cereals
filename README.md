# Cereals Mini-EDA
# Introduction
In this short EDA, I analyze a dataset containing information of numerous popular cereals. I aim to identify relationships and derive insights!

# Background
Since I studied as an Exercise Scientist, nutrition has been an interest and focus of mine for years now. As such, I wanted to incorporate that interest with my now-grown skills in data analysis!
I found this dataset via Kaggle, and you can view the it [here!](https://www.kaggle.com/datasets/crawford/80-cereals/data)

After looking at what data is available, and thinking about what makes this data unique, I decided on just a couple broad categories to explore:
1. Shelving-focused insights
   - Since this is a pretty unique piece of data to have, I really wanted to dive into this and find any relationships here
2. Nutrition-focused insights
   - Of course, with most of the data being from nutrition labels, I decided to look into this data further and explore patterns

For the full code, [click here!](https://github.com/ryanmjcu/Cereals/blob/main/cereal.sql)

# Data Inspection and Cleaning:
Before diving into any dataset too far, I always like to take a quick glance at general information and characteristics of the data. Typically with datasets online, there isn't any cleaning to be done, but it's good practice to make sure of that first.

```sql
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
```

Immediately, I saw something odd: the lowest_sugar value was -1... which isn't actually possible. So, I wanted to look at other MIN values to see if there are any other unrealistic values in this dataset:
```sql
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
```
As we can see, there are -1 values in the 'carbo', 'potass', and 'sugars' columns. Since this will affect future analysis, I decided that these needed to be changed to NULL. I didn't want to make these values just 0 though, as that would equally affect future analysis in ways that might not be representative of the true data.

```sql
UPDATE cereal
SET sugars = NULL
WHERE sugars = -1;

UPDATE cereal
SET carbo = NULL
WHERE carbo = -1;

UPDATE cereal
SET potass = NULL
WHERE potass = -1;
```
Now with that out of the way, we can actually get to analysis.

# Analysis

### General analysis
After inspection and cleaning, I like to look at very surface-level insights to get the important baseline questions out of the way:
- What is the average rating of all the products, and what are the top 5?

Average rating:

| avg_rating|
|-----------|
| 42.67     |
  
Top 5:
  
| name                    | rating     |
|-------------------------------|------------|
| All-Bran with Extra Fiber     | 93.704912  |
| Shredded Wheat 'n'Bran        | 74.472949  |
| Shredded Wheat spoon size     | 72.801787  |
| 100% Bran                     | 68.402973  |
| Shredded Wheat                | 68.235885  |

- What manufacturer makes the most products of this data?

| mfr| product_count | perc_of_cereals |
|----|-----------|-----------------|
| K | 23         | 29.87           |

### Shelving insights
Now to dive into the first broad category of data as mentioned earlier, shelving. I think this is a very cool and unique piece of data to have, so I found out the following:

- How do ratings vary by shelf?
  
| shelf | avg_rating |
|--------------|----------------|
| 3            | 45.22          |
| 2            | 34.97          |
| 1            | 46.15          |

Interestingly, the top and bottom shelves have very similar, and slightly above average, ratings. Meanwhile, the middle shelf has a somewhat significant drop in average rating. Many things could be true about this. For example, maybe the middle shelf sells the most, and as such has a much larger set of ratings with many outliers to pull from. Unfortunately, the data we're given can't point us to an exact answer though.

- What does sugar content look like per shelf?

| shelf | avg_sugars |
|--------------|--------------------|
| 3            | 6.53               |
| 2            | 9.62               |
| 1            | 5.11               |

Looks like the middle shelf has cereals with a great deal more sugars. This lines up with my own anecdotal experience, where I notice that the more popular cereals (which tend to be the sugary ones) are usually in the middle shelf, while the more health-focused (and therefore less sugary) ones are typically on the top and bottom shelves in the supermarket.

This could also align with that hypothesis from the last table, where the middle shelf has the most-bought cereals, which again could mean a wider range of ratings.

- What shelves do the top 3 manufactureres (by product count) stock their items on?
  I was curious to see if manufacturers who occupy more of the market have their products stocked on certain shelves. To accomplish this, I used a CTE to first find the top manufacturers by product count, and then I could select the count of products they each have grouped by shelf.

 ```sql
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
```
Assuming the manufacturers have a say in how their products get stocked, it seems that they have a slight preference for the top shelf. However, this difference does seem small and as such, I won't put too much stock in it (no pun intended).

- What are the top 3 rated products by shelf?
To answer this, I needed to "rank" the products in some way. And obviously that would be with the RANK() function. So I utilized the window function to rank the ratings, partitioned by the shelf.

```sql
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
```
A couple of insights from this data: First, we can see the disparity in ratings by shelf among these products. The middle shelf has noticably lower ratings than the top and bottom shelves. Second, the bottom shelf is dominated by a single line of products: Shredded Wheat cereals. This points to the manufacturer recognizing that consumers liked the original product, and as such they riffed on it to create more variety within that line.

### Nutritional Insights

- What cereals have the "best" (lowest) calorie-to-serving size ratio?

| name   | cals_per_serving |
|---------------|----------------------|
| Puffed Rice   | 50.00                |
| Puffed Wheat  | 50.00                |
| Kix           | 73.33                |

Here we see that plain, less flavorful cereals win this category. Unsurprisingly so, as more add-ins and sugary content would bump up that cals per serving.

- What are the most filling cereals?
Characteristics that define the most filling cereal are
1) High serving size - The obvious answer, as the higher volume will fill you up more
2) High fiber - Fiber content is associated with feeling of satiety in foods
3) High protein - protein is the most satiating macronutrient per gram consumed, so this is a great metric to use as well

| name                          | cups | fiber | protein) |
|-------------------------------------|------------------|-----------|-------------|
| Total Raisin Bran                   | 1                | 4         | 3           |
| Muesli Raisins, Dates, & Almonds    | 1                | 3         | 4           |
| Muesli Raisins, Peaches, & Pecans   | 1                | 3         | 4           |
| Nutri-grain Wheat                   | 1                | 3         | 3           |
| Total Whole Grain                   | 1                | 3         | 3

Here we see that depending on whether you value fiber or protein more for satiety, any of the top three cereals will bring feelings of fullness to a similar degree.

- For cereals of different sugar contents, how do their ratings stack up?
To answer this, I need to bucket the cereal contents since they vary widely. Then we can average the ratings and group by the buckets.
```sql
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
```
| sugar_level      | avg_rating     |
|------------------|----------------|
| Very Sugary      | 30.65          |
| Moderate Sugar   | 39.35          |
| Low Sugar        | 53.57          |

We can see a sharp rise in rating for those cereals which have lower (<= 5g/serving) sugar contents. This can easily point to consumer preferences for healthier, if not just lower sugar, options.

- Are big-box cereals more sugary than regular sized boxes?

| weight | avg_sugars |
|-------------|--------------------|
| 1.5         | 13.50              |
| 1.33        | 10.60              |
| 1.3         | 9.00               |
| 1.25        | 10.00              |
| 1           | 6.75               |
| 0.83        | 0.00               |
| 0.5         | 0.00               |

From this we can see that the higher-sugar cereals are more likely to be sold in larger boxes. This again indicates to the popularity of the more sugary cereals.

- What are the 3 most and 3 least calorically dense cereals?
I was thinking about the cereals with the best cal-to-serving size ratioes from earlier. And I wanted to see the opposite end of that spectrum, but rather than just re-tool the original query, I wanted to see both at once in order to contrast and gather further insight from the results set.

So, I decided to utilize two CTEs in this query for super easy readability. I made one to find the top 3, and the other finds the bottom 3, then finally I can UNION those two tables and order as needed!
```sql
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
```
Again we see the bottom 3 as the plainly flavored varieties, but now we can see how these types of cereal compare with the most calorically dense options. We see that cereals with nuts and fruits incorporated have greatly increased calories per serving size. This makes sense especially for the products with nuts, as those are a very calorie dense type of food.

# What I learned
- **Advanced Querying:** I learned to further utilize and apply window functions + CTEs in this mini-EDA!
- **Strengthened Understanding:** I was able to use my already solid foundational knowledge of basic functions to get started in analyzing this dataset
- **Can't Answer Every Question:** There were many times throughout this analysis that I wanted to dive further into things like number of sales and price, but I had to understand that every dataset has its limitations.

- # Ending Insights and Comments
- I was able to reasonably hypothesize that more sugary cereals are going to be sold more often than non-sugary counterparts. This was in part due to the facts presented in the data: found on the middle shelf, sold in larger boxes. But also inferred from the lower ratings, which I suggested earlier is due to a wider range of responses.
- Top manufacturers understand this data about their sugary cereals, and likely made these choices to shelve them in the middle and sell them in larger boxes, due to data analysis which probably looked a lot like this!


