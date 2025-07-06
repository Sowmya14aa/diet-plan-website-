<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
$host = 'localhost';
$dbname = 'diet_plan_db';
$username = 'root';
$password = 'Sowmya@#1406';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get form data
        $name = $_POST['name'] ?? '';
        $age = (int)($_POST['age'] ?? 0);
        $gender = $_POST['gender'] ?? '';
        $height = (float)($_POST['height'] ?? 0);
        $weight = (float)($_POST['weight'] ?? 0);
        $activity = $_POST['activity'] ?? '';
        $goal = $_POST['goal'] ?? '';
        
        // Validate input
        if (empty($name) || $age <= 0 || empty($gender) || $height <= 0 || $weight <= 0 || empty($activity) || empty($goal)) {
            throw new Exception('All fields are required and must be valid');
        }
        
        // Calculate BMI
        $height_m = $height / 100; // Convert cm to meters
        $bmi = round($weight / ($height_m * $height_m), 2);
        
        // Determine BMI category
        if ($bmi < 18.5) {
            $bmi_category = 'Underweight';
        } elseif ($bmi < 25) {
            $bmi_category = 'Normal weight';
        } elseif ($bmi < 30) {
            $bmi_category = 'Overweight';
        } else {
            $bmi_category = 'Obese';
        }
        
        // Calculate daily calories (Harris-Benedict equation)
        if ($gender === 'male') {
            $bmr = 88.362 + (13.397 * $weight) + (4.799 * $height) - (5.677 * $age);
        } else {
            $bmr = 447.593 + (9.247 * $weight) + (3.098 * $height) - (4.330 * $age);
        }
        
        // Activity multiplier
        $activity_multipliers = [
            'sedentary' => 1.2,
            'light' => 1.375,
            'moderate' => 1.55,
            'active' => 1.725,
            'very_active' => 1.9
        ];
        
        $daily_calories = round($bmr * $activity_multipliers[$activity]);
        
        // Adjust calories based on goal
        switch ($goal) {
            case 'lose_weight':
                $daily_calories -= 500; // 500 calorie deficit
                break;
            case 'gain_weight':
                $daily_calories += 500; // 500 calorie surplus
                break;
            case 'muscle_gain':
                $daily_calories += 300; // 300 calorie surplus
                break;
            // maintain_weight uses calculated calories as is
        }
        
        // Generate diet plan based on BMI category and goal
        $diet_plan = generateDietPlan($bmi_category, $goal, $daily_calories);
        $recommendations = generateRecommendations($bmi_category, $goal, $age, $gender);
        
        // Save to database
        $stmt = $pdo->prepare("INSERT INTO user_profiles (name, age, gender, height, weight, activity_level, goal, bmi, bmi_category, daily_calories, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())");
        $stmt->execute([$name, $age, $gender, $height, $weight, $activity, $goal, $bmi, $bmi_category, $daily_calories]);
        
        $user_id = $pdo->lastInsertId();
        
        // Save diet plan
        $stmt = $pdo->prepare("INSERT INTO diet_plans (user_id, meal_type, food_items, created_at) VALUES (?, ?, ?, NOW())");
        foreach ($diet_plan as $meal_type => $items) {
            $stmt->execute([$user_id, $meal_type, json_encode($items)]);
        }
        
        // Return response
        echo json_encode([
            'success' => true,
            'bmi' => $bmi,
            'bmi_category' => $bmi_category,
            'daily_calories' => $daily_calories,
            'diet_plan' => $diet_plan,
            'recommendations' => $recommendations,
            'user_id' => $user_id
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

function generateDietPlan($bmi_category, $goal, $calories) {
    $diet_plans = [
        'lose_weight' => [
            'breakfast' => [
                'Oatmeal with fresh berries and almonds (300 cal)',
                'Green tea or black coffee',
                '1 medium apple',
                'Low-fat Greek yogurt (100g)'
            ],
            'lunch' => [
                'Grilled chicken breast (150g) with quinoa (100g)',
                'Mixed green salad with olive oil dressing',
                'Steamed broccoli and carrots',
                'Water with lemon'
            ],
            'dinner' => [
                'Baked salmon (120g) with sweet potato (150g)',
                'Asparagus and bell peppers',
                'Small portion of brown rice (50g)',
                'Herbal tea'
            ],
            'snacks' => [
                'Handful of mixed nuts (30g)',
                'Celery sticks with hummus',
                'Fresh fruit (1 medium piece)',
                'Water (8-10 glasses daily)'
            ]
        ],
        'gain_weight' => [
            'breakfast' => [
                'Whole grain toast (2 slices) with avocado and eggs (2)',
                'Protein smoothie with banana and peanut butter',
                'Full-fat milk (1 glass)',
                'Mixed nuts and dried fruits'
            ],
            'lunch' => [
                'Chicken or turkey sandwich with whole grain bread',
                'Quinoa salad with vegetables and olive oil',
                'Cheese and crackers',
                'Fruit juice (1 glass)'
            ],
            'dinner' => [
                'Lean beef (180g) with mashed sweet potatoes',
                'Steamed vegetables with butter',
                'Brown rice (150g)',
                'Milk or protein shake'
            ],
            'snacks' => [
                'Trail mix with nuts and dried fruits',
                'Protein bars',
                'Whole grain crackers with cheese',
                'Smoothies with protein powder'
            ]
        ],
        'maintain_weight' => [
            'breakfast' => [
                'Whole grain cereal with milk and banana',
                'Scrambled eggs (2) with whole grain toast',
                'Orange juice (1 glass)',
                'Coffee or tea'
            ],
            'lunch' => [
                'Turkey and vegetable wrap with whole grain tortilla',
                'Mixed salad with chickpeas and olive oil',
                'Fresh fruit salad',
                'Water or herbal tea'
            ],
            'dinner' => [
                'Grilled fish (150g) with roasted vegetables',
                'Quinoa or brown rice (100g)',
                'Steamed green beans',
                'Sparkling water with lime'
            ],
            'snacks' => [
                'Greek yogurt with berries',
                'Apple slices with almond butter',
                'Whole grain crackers',
                'Plenty of water throughout the day'
            ]
        ],
        'muscle_gain' => [
            'breakfast' => [
                'Protein pancakes (3) with berries',
                'Scrambled eggs (3) with spinach',
                'Protein smoothie with banana',
                'Whole grain toast with almond butter'
            ],
            'lunch' => [
                'Grilled chicken breast (200g) with sweet potato',
                'Quinoa bowl with black beans and vegetables',
                'Greek yogurt (200g)',
                'Chocolate milk (1 glass)'
            ],
            'dinner' => [
                'Lean beef (200g) with quinoa and vegetables',
                'Salmon (150g) with brown rice',
                'Steamed broccoli with olive oil',
                'Protein shake before bed'
            ],
            'snacks' => [
                'Protein bars or shakes',
                'Cottage cheese with fruits',
                'Mixed nuts and seeds',
                'Tuna sandwich on whole grain bread'
            ]
        ]
    ];
    
    // Adjust plan based on BMI category
    $base_plan = $diet_plans[$goal] ?? $diet_plans['maintain_weight'];
    
    if ($bmi_category === 'Underweight') {
        // Add more calorie-dense foods
        $base_plan['snacks'][] = 'Protein smoothie with oats';
        $base_plan['snacks'][] = 'Dried fruits and nuts mix';
    } elseif ($bmi_category === 'Overweight' || $bmi_category === 'Obese') {
        // Focus on lower calorie, high fiber foods
        $base_plan['snacks'] = array_merge($base_plan['snacks'], [
            'Cucumber slices with hummus',
            'Herbal teas (unsweetened)',
            'Air-popped popcorn (small portion)'
        ]);
    }
    
    return $base_plan;
}

function generateRecommendations($bmi_category, $goal, $age, $gender) {
    $recommendations = [
        'Drink at least 8-10 glasses of water daily',
        'Eat regular meals and avoid skipping breakfast',
        'Include a variety of colorful fruits and vegetables',
        'Choose whole grains over refined grains',
        'Limit processed foods and added sugars'
    ];
    
    // Age-specific recommendations
    if ($age >= 50) {
        $recommendations[] = 'Increase calcium and vitamin D intake for bone health';
        $recommendations[] = 'Consider omega-3 supplements for heart health';
    }
    
    if ($age >= 65) {
        $recommendations[] = 'Focus on protein to maintain muscle mass';
        $recommendations[] = 'Stay hydrated as thirst sensation decreases with age';
    }
    
    // Gender-specific recommendations
    if ($gender === 'female') {
        $recommendations[] = 'Ensure adequate iron intake, especially if menstruating';
        $recommendations[] = 'Include folate-rich foods if planning pregnancy';
    }
    
    // BMI-specific recommendations
    switch ($bmi_category) {
        case 'Underweight':
            $recommendations[] = 'Eat calorie-dense, nutrient-rich foods';
            $recommendations[] = 'Consider consulting a healthcare provider';
            break;
        case 'Overweight':
        case 'Obese':
            $recommendations[] = 'Increase physical activity gradually';
            $recommendations[] = 'Focus on portion control';
            $recommendations[] = 'Consider consulting a registered dietitian';
            break;
    }
    
    // Goal-specific recommendations
    switch ($goal) {
        case 'lose_weight':
            $recommendations[] = 'Aim for 1-2 pounds of weight loss per week';
            $recommendations[] = 'Combine diet changes with regular exercise';
            break;
        case 'gain_weight':
            $recommendations[] = 'Eat frequent, smaller meals throughout the day';
            $recommendations[] = 'Include strength training exercises';
            break;
        case 'muscle_gain':
            $recommendations[] = 'Consume protein within 30 minutes after workouts';
            $recommendations[] = 'Get adequate sleep for muscle recovery';
            break;
    }
    
    return array_unique($recommendations);
}
?>