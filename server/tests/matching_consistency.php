<?php

declare(strict_types=1);

require dirname(__DIR__) . '/lib/bootstrap.php';

$failed = 0;

function check(bool $condition, string $label): void
{
    global $failed;
    if ($condition) {
        echo "ok  {$label}\n";
        return;
    }
    echo "FAIL {$label}\n";
    $failed += 1;
}

function expect_throw(callable $action, string $label): void
{
    try {
        $action();
        check(false, $label);
    } catch (RuntimeException $error) {
        check($error->getMessage() !== '', $label);
    }
}

$filters = validated_search_filters([
    'minAge' => 21,
    'maxAge' => 30,
    'gender' => 'Woman',
    'query' => 'kochi',
    'interests' => ['Coffee', 'Coffee'],
    'preferences' => ['Dating'],
]);
check($filters['minAge'] === 21 && $filters['maxAge'] === 30, 'age range is kept');
check($filters['gender'] === 'Woman', 'listed gender is kept');
check($filters['interests'] === ['Coffee'], 'duplicate interests collapse');
check($filters['query'] === 'kochi', 'search text is kept');

$nullGender = validated_search_filters(['gender' => null, 'minAge' => 18, 'maxAge' => 99]);
check($nullGender['gender'] === '', 'missing gender does not filter');

expect_throw(
    static fn () => validated_search_filters(['minAge' => 17, 'maxAge' => 30]),
    'ages under 18 are rejected'
);
expect_throw(
    static fn () => validated_search_filters(['minAge' => 30, 'maxAge' => 21]),
    'inverted age range is rejected'
);
expect_throw(
    static fn () => validated_search_filters(['minAge' => 18, 'maxAge' => 99, 'gender' => 'Other']),
    'unknown gender is rejected'
);
expect_throw(
    static fn () => validated_search_filters(['interests' => ['Hacking']]),
    'unknown interest is rejected'
);

$long = validated_search_filters(['query' => str_repeat('a', 50)]);
check(strlen($long['query']) === 40, 'search text is capped at 40 characters');
check(like_contains('100%_match') === '%100\\%\\_match%', 'search wildcards are escaped');

check(message_text('  hello  ') === 'hello', 'message text is trimmed');
check(message_text(str_repeat('a', 1000)) === str_repeat('a', 1000), '1000 character message is allowed');
expect_throw(static fn () => message_text('   '), 'blank message is rejected');
expect_throw(static fn () => message_text(str_repeat('a', 1001)), '1001 character message is rejected');

[$start, $end] = server_day_bounds();
$startAt = new DateTimeImmutable($start);
$endAt = new DateTimeImmutable($end);
check($endAt->getTimestamp() - $startAt->getTimestamp() === 86400, 'daily window is one server day');
$stamp = new DateTimeImmutable(now());
check($stamp >= $startAt && $stamp < $endAt, 'now() falls inside the server day window');

$api = file_get_contents(dirname(__DIR__) . '/api/index.php');
$schema = file_get_contents(dirname(__DIR__) . '/schema.sql');
check(is_string($api) && is_string($schema), 'api and schema can be read');
if (is_string($api) && is_string($schema)) {
    check(str_contains($schema, 'UNIQUE KEY swipe_pair'), 'one swipe per direction');
    check(str_contains($schema, 'UNIQUE KEY match_pair'), 'one match per pair');
    check(str_contains($schema, 'body VARCHAR(1000)'), 'messages are capped at 1000 characters');
    check(str_contains($schema, 'match_id INT UNSIGNED NOT NULL UNIQUE'), 'one conversation per match');
    check(substr_count($schema, 'ON DELETE CASCADE') >= 4, 'match deletion cascades the conversation');
    check(str_contains($api, "GET_LOCK(?, 3)") && str_contains($api, 'fym-pair-'), 'likes lock the pair');
    check(str_contains($api, 'INSERT IGNORE INTO matches'), 'repeat likes do not insert a second match');
    check(str_contains($api, 'LIMIT 30') && str_contains($api, 'LIMIT 50'), 'discover and search stay capped');
    check(str_contains($api, 'server_day_bounds()'), 'daily message cap uses the server day');
    check(!str_contains(function_slice($api, 'unmatch_user'), 'DELETE FROM blocks'), 'unmatch does not remove a block');
}

function function_slice(string $source, string $name): string
{
    $start = strpos($source, 'function ' . $name);
    if ($start === false) {
        return '';
    }
    $next = strpos($source, "\nfunction ", $start + 10);
    if ($next === false) {
        return substr($source, $start);
    }
    return substr($source, $start, $next - $start);
}

exit($failed === 0 ? 0 : 1);
