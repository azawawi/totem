use v6;

BEGIN { @*INC.push('lib') };

use Test;

plan 2;

use Totem;
ok 1, "'use Totem' worked!";
ok Totem.new, "Totem.new worked";
