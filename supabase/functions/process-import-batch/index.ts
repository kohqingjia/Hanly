import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "https://esm.sh/openai@4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { headers, rows } = await req.json();

    if (!Array.isArray(rows) || rows.length === 0) {
      return new Response(JSON.stringify({ words: [] }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    // Format rows as a readable table for the LLM
    const headerRow = (headers as string[]).join(" | ");
    const dataRows = (rows as string[][])
      .map((row) => row.join(" | "))
      .join("\n");

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      max_tokens: 6000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese vocabulary formatter. The user is importing their own vocabulary list into a Chinese learning app. You receive rows from a CSV or spreadsheet file and must convert each row into the app's word format.

COLUMN HEADERS: ${headerRow}

Your job:
1. Identify which columns contain the English term, Chinese characters, pinyin (if present), and any meaning/notes
2. For each row, produce a correctly formatted word object
3. If pinyin is missing, generate it from the Chinese characters (use tone marks: ā á ǎ à etc.)
4. If examples are missing, generate 1 realistic business/tech context example sentence
5. Generate character-level segments for both the word and the example sentence
6. Suggest 1-2 appropriate category tags

Return a JSON object with a "words" array. Each word must have exactly these fields:

{
  "english": "string — English term only, no Chinese or parentheticals",
  "chinese": "string — Simplified Chinese characters",
  "pinyin": "string — space-separated syllables with tone marks, one per character",
  "meaning": "string or null — only for untranslatable slang/jargon; null for standard terms",
  "examples": [
    {
      "zh": "string — full Chinese sentence",
      "en": "string — English translation",
      "segments": [
        {
          "char": "string — 1-4 characters forming one word unit",
          "py": "string — space-separated pinyin for this char group",
          "highlight": true or false — true if this segment is part of the vocabulary word
        }
      ]
    }
  ],
  "segments": [
    { "char": "string — single character", "py": "string — single pinyin syllable with tone" }
  ],
  "categories": ["string — 1-2 tags from: Software Engineering, Data & Analytics, Data Engineering, Cloud & Infrastructure, Machine Learning, Product Management, Business Strategy, Marketing, Finance, Operations, Design & UX, Cybersecurity, E-commerce, DevOps, Meetings & Communication, Project Management, General Business, General"]
}

RULES:
- "english": English only. No Chinese, no parentheses with translations.
- "pinyin": One syllable per character, space-separated, with tone marks.
- "meaning": null unless it's untranslatable slang.
- "examples": Exactly 1 example. The segments must cover every character in "zh". Highlight every character that belongs to the vocabulary word.
- "segments" (word-level): One object per Chinese character in the main word.
- If a row has no usable Chinese or English content, skip it (don't include in output).
- Skip header rows or rows that are clearly metadata.`,
        },
        {
          role: "user",
          content: `Please convert these ${rows.length} rows into word objects:\n\n${dataRows}`,
        },
      ],
    });

    const result = JSON.parse(completion.choices[0].message.content!);

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
