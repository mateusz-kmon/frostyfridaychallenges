select
  to_json(
    object_construct(
      'country_of_residence', country_of_residence,
      'superhero_name', superhero_name,
      'superpowers',
        coalesce(
          nullif(
              array_construct_compact(superpower, second_superpower, third_superpower)
            , array_construct_compact(null) 
          )
          , array_construct(null)
        )
    )
  ) as superhero_json
from week_14;