import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    // Auth client to verify the user
    const authClient = createClient(
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
    } = await authClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Service role client for global_words writes (bypasses RLS)
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { words } = await req.json();

    if (!Array.isArray(words) || words.length === 0) {
      return new Response(
        JSON.stringify({ error: "words must be a non-empty array" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let saved = 0;
    let skipped = 0;

    for (const word of words) {
      const { english, chinese, pinyin, meaning, examples, segments, categories } = word;

      if (!chinese || !pinyin || !english) {
        skipped++;
        continue;
      }

      try {
        // Step 1: Upsert into global_words
        const { data: existingGlobal } = await serviceClient
          .from("global_words")
          .select("id, add_count, categories")
          .eq("chinese", chinese)
          .eq("pinyin", pinyin)
          .maybeSingle();

        let globalWordId: string;

        if (existingGlobal) {
          globalWordId = existingGlobal.id;
          const mergedCategories = [
            ...new Set([
              ...(existingGlobal.categories || []),
              ...(categories || []),
            ]),
          ];
          await serviceClient
            .from("global_words")
            .update({
              add_count: (existingGlobal.add_count || 0) + 1,
              categories: mergedCategories,
              updated_at: new Date().toISOString(),
            })
            .eq("id", globalWordId);
        } else {
          const { data: newGlobal, error: globalError } = await serviceClient
            .from("global_words")
            .insert({
              chinese,
              pinyin,
              segments: segments || [],
              meaning: meaning || null,
              categories: categories || [],
            })
            .select("id")
            .single();

          if (globalError) throw globalError;
          globalWordId = newGlobal.id;
        }

        // Step 2: Insert user_word (review_card auto-created by trigger)
        const { error: userWordError } = await serviceClient
          .from("user_words")
          .insert({
            user_id: user.id,
            global_word_id: globalWordId,
            english,
            chinese,
            pinyin,
            meaning,
            notes: "",
            examples: examples || [],
            segments: segments || [],
            categories: categories || [],
            source: "onboarding",
            is_archived: false,
          });

        if (userWordError) {
          // Skip duplicates gracefully
          if (userWordError.code === "23505") {
            skipped++;
          } else {
            throw userWordError;
          }
        } else {
          saved++;
        }
      } catch (wordError) {
        skipped++;
      }
    }

    return new Response(JSON.stringify({ saved, skipped }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
