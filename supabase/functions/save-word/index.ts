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

    const { english, chinese, pinyin, meaning, notes, examples, segments, categories } =
      await req.json();

    // Validate required fields
    if (!chinese || !pinyin || !english) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: english, chinese, pinyin" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 1: Check global_words for existing match
    const { data: existingGlobal } = await serviceClient
      .from("global_words")
      .select("id, add_count, categories")
      .eq("chinese", chinese)
      .eq("pinyin", pinyin)
      .maybeSingle();

    let globalWordId: string;

    if (existingGlobal) {
      // Increment add_count, merge categories
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
      // Create new global word entry
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
    const { data: userWord, error: userWordError } = await serviceClient
      .from("user_words")
      .insert({
        user_id: user.id,
        global_word_id: globalWordId,
        english,
        chinese,
        pinyin,
        meaning,
        notes: notes || "",
        examples: examples || [],
        segments: segments || [],
        categories: categories || [],
        source: "translate",
        is_archived: false,
      })
      .select()
      .single();

    if (userWordError) throw userWordError;

    return new Response(JSON.stringify(userWord), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
