prelude

section

parameter α : Type

inductive foo : Type | a : α → foo | b
open foo

check (b : foo)

end

namespace bar
section

parameter α : Type

inductive foo : Type | a : α → foo | b
open foo

check (b : foo)

end
end bar
