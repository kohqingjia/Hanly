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

    const { text, user_context_summary, user_context_tags } = await req.json();
    if (!text || typeof text !== "string" || text.length > 1000) {
      return new Response(
        JSON.stringify({ error: "Invalid input. Provide 1-1000 characters." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build context-aware system prompt
    let contextClause = '';
    if (user_context_summary) {
      contextClause = `\n\nUser context: ${user_context_summary}`;
      if (user_context_tags?.length) {
        contextClause += `\nUser focus areas: ${user_context_tags.join(', ')}`;
      }
      contextClause += `\nTailor the translation, example, and meaning to this user's context and level.`;
    }

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese-English dictionary assistant for language learners.${contextClause}

The user will input a word or phrase in ANY format: English, Chinese characters, pinyin (with or without tones), misspelled Chinese, romanized Chinese, or a mixture. Infer the intended word/phrase from context and provide the best match.

CRITICAL: The "english" field must contain ONLY English text. Never include Chinese characters, pinyin, or parenthetical Chinese. Example: "human-computer interaction" NOT "人机交互 (human-computer interaction)".

Return a JSON object with:
- "english": the English word/phrase only (no Chinese characters or pinyin)
- "chinese": simplified Chinese
- "pinyin": pinyin with tone marks (e.g. māmā, not ma1ma1)
- "meaning": OPTIONAL. Set to null for concrete/literal nouns where the English is self-explanatory (e.g. data, apple, budget, computer). Only provide a short definition (under 15 words) for abstract concepts, idioms, or culturally-specific terms.
- "examples": array with exactly 1 example sentence object containing:
  - "zh": the full Chinese sentence
  - "en": English translation
  - "segments": array of pinyin segment objects for the sentence. Each object has "char" (1-4 Chinese characters forming one logical word), "py" (space-separated pinyin with tone marks, one syllable per character), and optionally "highlight": true for the segment containing the vocabulary word. Punctuation gets its own segment with empty "py". The concatenation of all "char" values must exactly equal the "zh" sentence.
- "tags_suggested": 1-2 tags from ONLY these categories: Technology, Finance, Healthcare, Education, Food & Dining, Travel & Tourism, Sports & Fitness, Music & Arts, Culture & History, Gaming, Science, Fashion, Daily Life, Casual
- "segments": array of objects, one per Chinese character of the main word, each with "char" and "py" (pinyin syllable with tone mark)

Example output for the word "data":
{"english":"data","chinese":"数据","pinyin":"shù jù","meaning":null,"examples":[{"zh":"我们需要分析这些数据。","en":"We need to analyze this data.","segments":[{"char":"我们","py":"wǒ men"},{"char":"需要","py":"xū yào"},{"char":"分析","py":"fēn xī"},{"char":"这些","py":"zhè xiē"},{"char":"数据","py":"shù jù","highlight":true},{"char":"。","py":""}]}],"tags_suggested":["Technology"],"segments":[{"char":"数","py":"shù"},{"char":"据","py":"jù"}]}

Always use proper tone marks in pinyin (ā á ǎ à, not a1 a2 a3 a4). Prefer natural, conversational Chinese.`,
        },
        {
          role: "user",
          content: text,
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
