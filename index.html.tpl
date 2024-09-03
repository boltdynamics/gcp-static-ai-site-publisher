<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>XPLORERS</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            background: linear-gradient(135deg, #12e739 0%, #fad0c4 99%, #fad0c4 100%);
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes slideIn {
            from { transform: translateY(-50px); }
            to { transform: translateY(0); }
        }

        h1 {
            font-size: 5em;
            color: white;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            animation: fadeIn 2s ease-out, slideIn 1s ease-out;
        }

        h3 {
            color: white;
            font-size: 1.4em;
            text-align: center;
            animation: fadeIn 3s ease-out;
        }

        .input-container {
            bottom: 20px;
            width: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
        }

        input[type="text"] {
            margin-top: 20px;
            padding: 10px;
            font-size: 1em;
            border: none;
            border-radius: 5px;
            box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            width: 80%;
            max-width: 400px;
        }

        input[type="text"]::placeholder {
            color: #ccc;
        }

        button {
            margin-top: 10px;
            padding: 10px;
            font-size: 1em;
            border: none;
            border-radius: 5px;
            background-color: #ffffff;
            color: black;
            cursor: pointer;
            box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        button:hover {
            background-color: #a498c1;
        }

        button:disabled {
            background-color: #ddd;
            cursor: not-allowed;
        }

        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top: 4px solid #000;
            border-radius: 50%;
            width: 14px;
            height: 14px;
            animation: spin 1s linear infinite;
            margin-left: 10px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        #response {
            flex-grow: 1;
            overflow-y: auto;
            width: 100%;
            padding: 20px;
            box-sizing: border-box;
        }
    </style>
</head>
<body>
    <h1>XPLORERS AI</h1>
    <div class="input-container">
        <input type="text" id="userQuery" placeholder="Ask a question..." />
        <button id="callAI">Send</button>
    </div>
    <div id="response"></div>

    <!-- Include marked.js library -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>

    <script>
        document.getElementById('callAI').addEventListener('click', async () => {
            const query = document.getElementById('userQuery').value;
            if (!query) {
                alert('Please enter a question.');
                return;
            }

            const button = document.getElementById('callAI');
            button.disabled = true;
            button.innerHTML = 'Loading...<div class="spinner"></div>';

            try {
                const response = await fetch('${cloud_function_url}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ query })
                });

                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }

                const data = await response.json();
                console.log('Response Data:', data);

                const markdownContent = data.candidates[0].content.parts[0].text;
                const htmlContent = marked.parse(markdownContent);
                document.getElementById('response').innerHTML = htmlContent;
            } catch (error) {
                console.error('Error calling AI:', error);
            } finally {
                button.disabled = false;
                button.innerHTML = 'Send';
            }
        });
    </script>
</body>
</html>
