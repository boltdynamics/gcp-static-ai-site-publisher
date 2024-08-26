import { Request, Response } from "@google-cloud/functions-framework";

export const askGemini = async (req: Request, res: Response): Promise<void> => {
    // Set CORS headers for preflight requests
    if (req.method === "OPTIONS") {
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type");
        res.set("Access-Control-Max-Age", "3600");
        res.status(204).send("");
        return;
    }

    try {
        const body = req.body;
        console.log(`BODY: ${JSON.stringify(body)}`);

        const query = body.query;
        console.log(`QUERY: ${query}`);

        const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${process.env.GEMINI_AI_API_KEY}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: query }] }],
                }),
            }
        );

        const data = await response.json();
        res.set("Access-Control-Allow-Origin", "*");
        res.status(200).send(JSON.stringify(data));
    } catch (error) {
        console.error("Error calling AI:", error);
        res.set("Access-Control-Allow-Origin", "*");
        res.status(500).send("Internal Server Error");
    }
};

export default askGemini;
