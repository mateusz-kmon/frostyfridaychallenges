select 
  to_json(
    object_construct(      
      'country_of_residence', country_of_residence,
      'superhero_name', superhero_name, 
      'superpowers', 
        case 
        when coalesce(superpower, second_superpower, third_superpower) is null 
          then array_construct(null) 
        else array_construct_compact(superpower, second_superpower, third_superpower)
        end
    )
  ) as superhero_json 
from week_14;