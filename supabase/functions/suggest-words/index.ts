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

    const { context_summary, context_tags, count = 4, existing_words = [] } = await req.json();

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const tagsList = (context_tags || []).join(", ");

    const existingWordsSection = existing_words.length > 0
      ? `\n\nDo NOT generate any of these already-generated words:\n${existing_words.map((w: { english: string; chinese: string }) => `- ${w.english} (${w.chinese})`).join("\n")}`
      : "";

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      max_tokens: 4000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese technical and business vocabulary recommender for professionals working at major Chinese tech companies (Tencent, ByteDance, Alibaba, Huawei, etc.). Return ONLY valid JSON.
User profile: ${context_summary || "Professional needing tech/business Chinese vocabulary"}
Focus areas: ${tagsList || "general tech"}

Generate exactly ${count} technical and business Chinese vocabulary words that are commonly used in Chinese tech company workplaces. These should be advanced compound terms — NOT basic everyday vocabulary. Focus on terms used in meetings, documents, technical discussions, and business communication at companies like Tencent, ByteDance, and Alibaba.

Example level of complexity: 架构 (architecture), 全链路 (end-to-end), 数据建模 (data modeling), 分层模型 (hierarchical modeling), 基础设施 (infrastructure), 监控 (monitoring), 迭代 (iteration), 复盘 (retrospective/review), 对齐 (alignment), 赋能 (empowerment), 拉通 (cross-team alignment), 颗粒度 (granularity).

Tailor the words to the user's focus areas. Order from moderately advanced to highly specialized.${existingWordsSection}

Return a JSON object with a "words" array. Here is an example word object:
{"english":"data modeling","chinese":"数据建模","pinyin":"shù jù jiàn mó","meaning":null,"examples":[{"zh":"数据建模是数据仓库项目的第一步。","en":"Data modeling is the first step in a data warehouse project.","segments":[{"char":"数据","py":"shù jù","highlight":true},{"char":"建模","py":"jiàn mó","highlight":true},{"char":"是","py":"shì"},{"char":"数据","py":"shù jù"},{"char":"仓库","py":"cāng kù"},{"char":"项目","py":"xiàng mù"},{"char":"的","py":"de"},{"char":"第一步","py":"dì yī bù"},{"char":"。","py":""}]}],"tags_suggested":["Data & Analytics"],"segments":[{"char":"数","py":"shù"},{"char":"据","py":"jù"},{"char":"建","py":"jiàn"},{"char":"模","py":"mó"}]}

Here is a HIGHLIGHT example for "infrastructure" (基础设施) — note EVERY character of the vocab word gets highlight:
{"zh":"公司正在升级云基础设施。","en":"The company is upgrading its cloud infrastructure.","segments":[{"char":"公司","py":"gōng sī"},{"char":"正在","py":"zhèng zài"},{"char":"升级","py":"shēng jí"},{"char":"云","py":"yún"},{"char":"基础","py":"jī chǔ","highlight":true},{"char":"设施","py":"shè shī","highlight":true},{"char":"。","py":""}]}

STRICT RULES — violating any rule is an error:

1. "english": ONLY English words. NEVER include Chinese characters, pinyin, or parenthetical translations.
   WRONG: "技术能力 (technical skills)" → RIGHT: "technical skills"

2. "chinese": Simplified Chinese characters only.

3. "pinyin": Space-separated syllables with tone marks. ONE syllable PER character.
   CORRECT: "shù jù cāng kù" (4 characters = 4 syllables separated by spaces)
   WRONG: "shùjù cāngkù" (merged syllables)
   Always use tone marks: ā á ǎ à ē é ě è ī í ǐ ì ō ó ǒ ò ū ú ǔ ù ǖ ǘ ǚ ǜ

4. "meaning": null BY DEFAULT. Only provide a short definition (max 12 words) for:
   - Chinese tech/business slang or jargon not directly translatable (e.g. 复盘 → "post-mortem review; to review and learn from past actions")
   - Abstract or culturally-specific business concepts (e.g. 赋能 → "to empower; enable through resources or capability")
   Set to null for terms where the English is self-explanatory: data modeling, infrastructure, architecture, project management, etc.

5. "examples": Array with exactly 1 object. CRITICAL — each example MUST include:
   - "zh": Full Chinese sentence using the word in a realistic tech/business workplace context
   - "en": English translation
   - "segments": REQUIRED array covering EVERY character in "zh". Each segment has:
     - "char": 1-4 Chinese characters forming one logical word
     - "py": Space-separated pinyin with tone marks (one syllable per char in "char")
     - "highlight": true on EVERY segment that contains ANY character from the vocabulary word. For 基础设施 split as [基础, 设施], BOTH get "highlight": true. NEVER leave any character of the vocab word unhighlighted.
     Punctuation gets its own segment with "py": ""
     Concatenation of all "char" values MUST exactly equal the "zh" string.

6. "tags_suggested": 1-2 tags from ONLY this list: Software Engineering, Data & Analytics, Data Engineering, Cloud & Infrastructure, Machine Learning, Product Management, Business Strategy, Marketing, Finance, Operations, Design & UX, Cybersecurity, E-commerce, DevOps, Meetings & Communication, Project Management, General Business, General
   Choose the MOST SPECIFIC and RELEVANT tag. Use "General Business" for broadly applicable business terms. Use "Meetings & Communication" for workplace interaction terms. Use "General" for words with broad everyday utility not tied to any technical or business domain (e.g., common workplace action verbs, universal phrases used across all roles).

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
