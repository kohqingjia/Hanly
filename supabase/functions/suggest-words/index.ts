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

    const { context_summary, context_tags, chinese_level } = await req.json();

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const tagsList = (context_tags || []).join(", ");

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      max_tokens: 10000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese vocabulary recommender. Return ONLY valid JSON.
User profile: ${context_summary || "General learner"}
Focus areas: ${tagsList || "general"}
Chinese level: ${chinese_level || "beginner"}

Generate exactly 12 starter vocabulary words. Mix everyday words with words relevant to the user's interests. Order from simpler to more advanced.

Return a JSON object with a "words" array. Here is an example word object:
{"english":"data","chinese":"数据","pinyin":"shù jù","meaning":null,"examples":[{"zh":"我们需要分析这些数据。","en":"We need to analyze this data.","segments":[{"char":"我们","py":"wǒ men"},{"char":"需要","py":"xū yào"},{"char":"分析","py":"fēn xī"},{"char":"这些","py":"zhè xiē"},{"char":"数据","py":"shù jù","highlight":true},{"char":"。","py":""}]}],"tags_suggested":["Technology"],"segments":[{"char":"数","py":"shù"},{"char":"据","py":"jù"}]}

Here is a HIGHLIGHT example for "sales" (销售) — note EVERY character of the vocab word gets highlight:
{"zh":"销售是公司最重要的部门之一。","en":"Sales is one of the most important departments in the company.","segments":[{"char":"销","py":"xiāo","highlight":true},{"char":"售","py":"shòu","highlight":true},{"char":"是","py":"shì"},{"char":"公司","py":"gōng sī"},{"char":"最","py":"zuì"},{"char":"重要","py":"zhòng yào"},{"char":"的","py":"de"},{"char":"部门","py":"bù mén"},{"char":"之一","py":"zhī yī"},{"char":"。","py":""}]}

STRICT RULES — violating any rule is an error:

1. "english": ONLY English words. NEVER include Chinese characters, pinyin, or parenthetical translations.
   WRONG: "技术能力 (technical skills)" → RIGHT: "technical skills"

2. "chinese": Simplified Chinese characters only.

3. "pinyin": Space-separated syllables with tone marks. ONE syllable PER character.
   CORRECT: "shù jù cāng kù" (4 characters = 4 syllables separated by spaces)
   WRONG: "shùjù cāngkù" (merged syllables)
   Always use tone marks: ā á ǎ à ē é ě è ī í ǐ ì ō ó ǒ ò ū ú ǔ ù ǖ ǘ ǚ ǜ

4. "meaning": null BY DEFAULT. Only provide a short definition (max 12 words) for idioms, slang, or culturally-specific concepts.
   Set to null for: concrete nouns, verbs, adjectives, compound nouns, technical terms where the English is self-explanatory.
   null examples: data, apple, computer, data warehouse, project management, technical skills, hospital, beautiful

5. "examples": Array with exactly 1 object. CRITICAL — each example MUST include:
   - "zh": Full Chinese sentence
   - "en": English translation
   - "segments": REQUIRED array covering EVERY character in "zh". Each segment has:
     - "char": 1-4 Chinese characters forming one logical word
     - "py": Space-separated pinyin with tone marks (one syllable per char in "char")
     - "highlight": true on EVERY segment that contains ANY character from the vocabulary word. For 销售, if segmented as [销, 售], BOTH get "highlight": true. For 数据仓库 split as [数据, 仓库], BOTH get "highlight": true. NEVER leave any character of the vocab word unhighlighted.
     Punctuation gets its own segment with "py": ""
     Concatenation of all "char" values MUST exactly equal the "zh" string.

6. "tags_suggested": 1-2 tags from ONLY this list: Conversational, Casual Speaking, Daily Life, Social & Networking, Family & Relationships, Technology, Finance, Healthcare, Legal, Education, Marketing, Hospitality, Manufacturing, Real Estate, Media, Government, Retail, Food & Dining, Sports & Fitness, Music & Arts, Travel & Tourism, Gaming, Science, Fashion, Environment, Culture & History
   NEVER use tags outside this list.
   Choose the MOST SPECIFIC and RELEVANT tag for each word. General/common words should use "Daily Life" or "Conversational". Only use niche tags like "Manufacturing" or "Media" if the word is truly domain-specific to that field.
   Examples: 项目(project)→["Daily Life"], 团队(team)→["Social & Networking"], 销售(sales)→["Retail"], 医生(doctor)→["Healthcare"], 电脑(computer)→["Technology"]

7. "segments": Array for the main word. One object per Chinese character, each with "char" (single character) and "py" (one pinyin syllable with tone mark).`,
        },
        {
          role: "user",
          content: "Generate starter vocabulary for me.",
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
