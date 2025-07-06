-- Create database
CREATE DATABASE IF NOT EXISTS diet_plan_db;
USE diet_plan_db;

-- Create user profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('male', 'female') NOT NULL,
    height DECIMAL(5,2) NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    activity_level ENUM('sedentary', 'light', 'moderate', 'active', 'very_active') NOT NULL,
    goal ENUM('lose_weight', 'maintain_weight', 'gain_weight', 'muscle_gain') NOT NULL,
    bmi DECIMAL(5,2) NOT NULL,
    bmi_category VARCHAR(20) NOT NULL,
    daily_calories INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create diet plans table
CREATE TABLE IF NOT EXISTS diet_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    meal_type ENUM('breakfast', 'lunch', 'dinner', 'snacks') NOT NULL,
    food_items JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
);

-- Create nutrition feedback table (for Power BI integration)
CREATE TABLE IF NOT EXISTS nutrition_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    feedback_date DATE NOT NULL,
    calories_consumed INT,
    protein_intake DECIMAL(5,2),
    carbs_intake DECIMAL(5,2),
    fat_intake DECIMAL(5,2),
    water_intake DECIMAL(5,2),
    exercise_minutes INT DEFAULT 0,
    weight_recorded DECIMAL(5,2),
    mood_rating INT CHECK (mood_rating >= 1 AND mood_rating <= 5),
    energy_level INT CHECK (energy_level >= 1 AND energy_level <= 5),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
);

-- Create food database table
CREATE TABLE IF NOT EXISTS food_database (
    id INT AUTO_INCREMENT PRIMARY KEY,
    food_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    calories_per_100g INT NOT NULL,
    protein_per_100g DECIMAL(5,2) NOT NULL,
    carbs_per_100g DECIMAL(5,2) NOT NULL,
    fat_per_100g DECIMAL(5,2) NOT NULL,
    fiber_per_100g DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample food data
INSERT INTO food_database (food_name, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g) VALUES
('Chicken Breast', 'Protein', 165, 31.0, 0.0, 3.6, 0.0),
('Salmon', 'Protein', 208, 25.4, 0.0, 12.4, 0.0),
('Brown Rice', 'Grain', 111, 2.6, 23.0, 0.9, 1.8),
('Quinoa', 'Grain', 120, 4.4, 21.3, 1.9, 2.8),
('Broccoli', 'Vegetable', 34, 2.8, 7.0, 0.4, 2.6),
('Spinach', 'Vegetable', 23, 2.9, 3.6, 0.4, 2.2),
('Avocado', 'Fruit', 160, 2.0, 8.5, 14.7, 6.7),
('Banana', 'Fruit', 89, 1.1, 22.8, 0.3, 2.6),
('Almonds', 'Nuts', 579, 21.2, 21.6, 49.9, 12.5),
('Greek Yogurt', 'Dairy', 59, 10.0, 3.6, 0.4, 0.0),
('Eggs', 'Protein', 155, 13.0, 1.1, 11.0, 0.0),
('Sweet Potato', 'Vegetable', 86, 1.6, 20.1, 0.1, 3.0),
('Oats', 'Grain', 389, 16.9, 66.3, 6.9, 10.6),
('Tuna', 'Protein', 144, 30.0, 0.0, 1.0, 0.0),
('Olive Oil', 'Fat', 884, 0.0, 0.0, 100.0, 0.0),
('Hummus', 'Protein', 166, 8.0, 14.3, 9.6, 6.0),
('Apple', 'Fruit', 52, 0.3, 13.8, 0.2, 2.4),
('Cucumber', 'Vegetable', 16, 0.7, 3.6, 0.1, 0.5),
('Lentils', 'Protein', 116, 9.0, 20.1, 0.4, 7.9),
('Cottage Cheese', 'Dairy', 98, 11.1, 3.4, 4.3, 0.0),
('Whole Wheat Bread', 'Grain', 247, 13.0, 41.0, 4.2, 7.0);

-- Create views for Power BI dashboard
CREATE VIEW user_bmi_trends AS
SELECT 
    u.id,
    u.name,
    u.age,
    u.gender,
    u.bmi,
    u.bmi_category,
    u.daily_calories,
    u.goal,
    u.created_at,
    CASE 
        WHEN u.bmi < 18.5 THEN 'Underweight'
        WHEN u.bmi BETWEEN 18.5 AND 24.9 THEN 'Normal'
        WHEN u.bmi BETWEEN 25 AND 29.9 THEN 'Overweight'
        ELSE 'Obese'
    END as bmi_status
FROM user_profiles u;

CREATE VIEW nutrition_analytics AS
SELECT 
    nf.user_id,
    u.name,
    u.age,
    u.gender,
    u.bmi_category,
    nf.feedback_date,
    nf.calories_consumed,
    nf.protein_intake,
    nf.carbs_intake,
    nf.fat_intake,
    nf.water_intake,
    nf.exercise_minutes,
    nf.weight_recorded,
    nf.mood_rating,
    nf.energy_level,
    u.daily_calories as target_calories,
    (nf.calories_consumed - u.daily_calories) as calorie_variance
FROM nutrition_feedback nf
JOIN user_profiles u ON nf.user_id = u.id;

CREATE VIEW weekly_progress AS
SELECT 
    user_id,
    YEAR(feedback_date) as year,
    WEEK(feedback_date) as week,
    AVG(calories_consumed) as avg_calories,
    AVG(protein_intake) as avg_protein,
    AVG(carbs_intake) as avg_carbs,
    AVG(fat_intake) as avg_fat,
    AVG(water_intake) as avg_water,
    SUM(exercise_minutes) as total_exercise,
    AVG(mood_rating) as avg_mood,
    AVG(energy_level) as avg_energy,
    MIN(weight_recorded) as min_weight,
    MAX(weight_recorded) as max_weight,
    COUNT(*) as days_tracked
FROM nutrition_feedback
GROUP BY user_id, YEAR(feedback_date), WEEK(feedback_date);

-- Insert sample data for testing
INSERT INTO user_profiles (name, age, gender, height, weight, activity_level, goal, bmi, bmi_category, daily_calories) VALUES
('John Doe', 28, 'male', 175.0, 70.0, 'moderate', 'maintain_weight', 22.86, 'Normal weight', 2200),
('Jane Smith', 32, 'female', 165.0, 60.0, 'light', 'lose_weight', 22.04, 'Normal weight', 1700),
('Mike Johnson', 45, 'male', 180.0, 85.0, 'active', 'lose_weight', 26.23, 'Overweight', 2300),
('Sarah Wilson', 29, 'female', 170.0, 55.0, 'sedentary', 'gain_weight', 19.03, 'Normal weight', 1900);

-- Insert sample nutrition feedback
INSERT INTO nutrition_feedback (user_id, feedback_date, calories_consumed, protein_intake, carbs_intake, fat_intake, water_intake, exercise_minutes, weight_recorded, mood_rating, energy_level, notes) VALUES
(1, '2024-01-15', 2150, 120.5, 280.0, 85.0, 2.5, 45, 69.8, 4, 4, 'Feeling good, stuck to meal plan'),
(1, '2024-01-16', 2300, 130.0, 295.0, 90.0, 2.8, 60, 69.7, 5, 5, 'Great workout today'),
(2, '2024-01-15', 1650, 95.0, 180.0, 65.0, 3.0, 30, 59.5, 3, 3, 'Felt hungry in the evening'),
(2, '2024-01-16', 1700, 100.0, 185.0, 70.0, 3.2, 45, 59.3, 4, 4, 'Better energy today'),
(3, '2024-01-15', 2250, 140.0, 260.0, 95.0, 2.2, 75, 84.5, 4, 4, 'Good progress on weight loss'),
(3, '2024-01-16', 2100, 135.0, 240.0, 88.0, 2.8, 90, 84.2, 5, 5, 'Excellent workout, feeling strong'),
(4, '2024-01-15', 1950, 85.0, 250.0, 75.0, 2.0, 20, 55.2, 3, 3, 'Need to eat more consistently'),
(4, '2024-01-16', 2000, 90.0, 260.0, 80.0, 2.5, 25, 55.4, 4, 4, 'Added protein shake');

-- Create indexes for better performance
CREATE INDEX idx_user_profiles_bmi ON user_profiles(bmi);
CREATE INDEX idx_user_profiles_goal ON user_profiles(goal);
CREATE INDEX idx_user_profiles_created_at ON user_profiles(created_at);
CREATE INDEX idx_nutrition_feedback_date ON nutrition_feedback(feedback_date);
CREATE INDEX idx_nutrition_feedback_user_date ON nutrition_feedback(user_id, feedback_date);
CREATE INDEX idx_diet_plans_user_id ON diet_plans(user_id);

-- Create stored procedures for common operations
DELIMITER //

CREATE PROCEDURE GetUserDietPlan(IN p_user_id INT)
BEGIN
    SELECT 
        up.name,
        up.bmi,
        up.bmi_category,
        up.daily_calories,
        up.goal,
        dp.meal_type,
        dp.food_items
    FROM user_profiles up
    LEFT JOIN diet_plans dp ON up.id = dp.user_id
    WHERE up.id = p_user_id;
END //

CREATE PROCEDURE GetUserProgressStats(IN p_user_id INT, IN p_days INT)
BEGIN
    SELECT 
        COUNT(*) as total_days,
        AVG(calories_consumed) as avg_calories,
        AVG(protein_intake) as avg_protein,
        AVG(weight_recorded) as avg_weight,
        AVG(mood_rating) as avg_mood,
        AVG(energy_level) as avg_energy,
        SUM(exercise_minutes) as total_exercise
    FROM nutrition_feedback
    WHERE user_id = p_user_id 
    AND feedback_date >= DATE_SUB(CURDATE(), INTERVAL p_days DAY);
END //

CREATE PROCEDURE GetBMIDistribution()
BEGIN
    SELECT 
        bmi_category,
        COUNT(*) as user_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_profiles), 2) as percentage
    FROM user_profiles
    GROUP BY bmi_category
    ORDER BY user_count DESC;
END //

DELIMITER ;

-- Create triggers for data validation
DELIMITER //

CREATE TRIGGER validate_bmi_before_insert
BEFORE INSERT ON user_profiles
FOR EACH ROW
BEGIN
    DECLARE calculated_bmi DECIMAL(5,2);
    SET calculated_bmi = NEW.weight / ((NEW.height/100) * (NEW.height/100));
    
    IF ABS(NEW.bmi - calculated_bmi) > 0.1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BMI calculation mismatch';
    END IF;
END //

CREATE TRIGGER validate_nutrition_feedback
BEFORE INSERT ON nutrition_feedback
FOR EACH ROW
BEGIN
    IF NEW.calories_consumed < 0 OR NEW.calories_consumed > 10000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid calories consumed value';
    END IF;
    
    IF NEW.water_intake < 0 OR NEW.water_intake > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid water intake value';
    END IF;
END //

DELIMITER ;