<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World & Jokes</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        .hello-world {
            color: #667eea;
            font-size: 3em;
            margin-bottom: 30px;
            font-weight: bold;
        }
        .joke-container {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 15px;
            margin: 30px 0;
            border-left: 5px solid #667eea;
        }
        .joke {
            font-size: 1.3em;
            color: #555;
            line-height: 1.6;
        }
        .punchline {
            font-weight: bold;
            color: #e74c3c;
            font-size: 1.4em;
            margin-top: 15px;
        }
        .emoji {
            font-size: 2em;
            margin: 20px 0;
        }
        .refresh {
            background: #667eea;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 1.1em;
            margin-top: 20px;
            transition: background 0.3s;
        }
        .refresh:hover {
            background: #5a67d8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="hello-world">Hello World! 🌍</div>
        
        <h1>Welcome to our PHP Page!</h1>
        
        <div class="emoji">😄 🤣 😂</div>
        
        <div class="joke-container">
            <div class="joke">
                <?php
                // Array of funny jokes
                $jokes = [
                    "Why don't scientists trust atoms?",
                    "Why did the scarecrow win an award?",
                    "What do you call a fake noodle?",
                    "Why don't eggs tell jokes?",
                    "Why did the math book look so sad?"
                ];
                
                $punchlines = [
                    "Because they make up everything!",
                    "Because he was outstanding in his field!",
                    "An impasta!",
                    "Because they'd crack each other up!",
                    "Because it had too many problems!"
                ];
                
                // Get a random joke
                $randomIndex = array_rand($jokes);
                $selectedJoke = $jokes[$randomIndex];
                $selectedPunchline = $punchlines[$randomIndex];
                
                echo $selectedJoke;
                ?>
            </div>
            <div class="punchline">
                <?php echo $selectedPunchline; ?>
            </div>
        </div>
        
        <div class="emoji">🎉 🥳 ✨</div>
        
        <p>Current server time: <?php echo date('Y-m-d H:i:s'); ?></p>
        
        <button class="refresh" onclick="location.reload()">
            Get Another Joke! 🔄
        </button>
    </div>
</body>
</html>