<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $error = 'The form expired. Try again.';
    } else {
        try {
            replace_network_ad_settings(network_ad_from_post($_POST));
            log_moderation((int) $admin['id'], 'network-ads', null, 'Network ad settings saved');
            $notice = 'Network ads saved.';
        } catch (RuntimeException $exception) {
            $error = $exception->getMessage();
        }
    }
}

$row = network_ad_row();

function network_value(array $row, string $column): string
{
    return h((string) ($row[$column] ?? ''));
}

function network_checked(array $row, string $column): string
{
    return (int) ($row[$column] ?? 0) === 1 ? ' checked' : '';
}

function network_selected(array $row, string $column, string $value): string
{
    return (string) ($row[$column] ?? '') === $value ? ' selected' : '';
}

function network_input(array $row, string $label, string $name, int $max = 120): string
{
    return '<label>' . h($label)
        . '<input name="' . h($name) . '" maxlength="' . $max . '" value="'
        . network_value($row, $name) . '"></label>';
}

$body = '<h1>Network ads</h1>'
    . '<p>Turn a section on, then paste the IDs you have. If more than one network that this app can show is filled in, the app picks one at random.</p>'
    . '<p>This Android build shows AdMob and a Monetag direct link. Appnext, Facebook, Start.io, Unity Ads, IronSource, and Wortise IDs are saved with the same switches. This build does not request ads from those networks yet.</p>'
    . '<p>AdMob does not allow its ads inside chats, so leave “Show AdMob in chats” on No. A chat interstitial uses Monetag when that link is set. Reports and account deletion never show these ads.</p>'
    . '<p>The installed app uses Google’s test AdMob application ID until a new build contains yours. Test banner <code>ca-app-pub-3940256099942544/6300978111</code>, interstitial <code>ca-app-pub-3940256099942544/1033173712</code>, app open <code>ca-app-pub-3940256099942544/9257395921</code>.</p>'
    . status_html($notice, $error)
    . '<form method="post" class="ads-settings">' . csrf_field();

$body .= '<h2><label class="check"><input type="checkbox" name="banner_enabled" value="1"'
    . network_checked($row, 'banner_enabled') . '> Banner ads</label></h2>';
$body .= network_input($row, 'AdMob App ID', 'admob_app_id', 80);
$body .= network_input($row, 'AdMob ad unit ID', 'admob_banner_unit', 80);
$body .= network_input($row, 'Appnext placement ID', 'appnext_banner');
$body .= network_input($row, 'Facebook placement ID', 'facebook_banner');
$body .= network_input($row, 'Start.io App ID', 'startio_app_id');
$body .= network_input($row, 'Unity Ads Game ID', 'unity_game_id', 80);
$body .= network_input($row, 'Unity Ads placement ID', 'unity_banner_placement', 80);
$body .= network_input($row, 'IronSource App ID', 'ironsource_app_key', 80);
$body .= network_input($row, 'Wortise App ID', 'wortise_app_id', 80);
$body .= network_input($row, 'Wortise ad unit ID', 'wortise_banner_unit', 80);
$body .= '<p class="hint">If you set more than one network that this app can show, banner ads appear randomly.</p>';
$body .= '<label>Ads position<select name="banner_position">'
    . '<option value="bottom"' . network_selected($row, 'banner_position', 'bottom') . '>Bottom</option>'
    . '<option value="top"' . network_selected($row, 'banner_position', 'top') . '>Top</option>'
    . '</select></label>';
$body .= '<label>Ads size<select name="banner_size">'
    . '<option value="normal"' . network_selected($row, 'banner_size', 'normal') . '>Normal</option>'
    . '<option value="large"' . network_selected($row, 'banner_size', 'large') . '>Large</option>'
    . '</select><span class="hint">Size applies to portrait banners.</span></label>';
$body .= '<label>Show AdMob in chats<select name="admob_in_chats">'
    . '<option value="0"' . network_selected($row, 'admob_in_chats', '0') . '>No</option>'
    . '<option value="1"' . network_selected($row, 'admob_in_chats', '1') . '>Yes</option>'
    . '</select><span class="hint">AdMob does not allow ads in chats.</span></label>';

$body .= '<h2><label class="check"><input type="checkbox" name="interstitial_enabled" value="1"'
    . network_checked($row, 'interstitial_enabled') . '> Interstitial ads</label></h2>';
$body .= network_input($row, 'AdMob ad unit ID', 'admob_interstitial_unit', 80);
$body .= network_input($row, 'Appnext placement ID', 'appnext_interstitial');
$body .= network_input($row, 'Facebook placement ID', 'facebook_interstitial');
$body .= '<p class="hint">Start.io, Unity Ads, and IronSource use the App ID or Game ID from the banner section.</p>';
$body .= network_input($row, 'Unity Ads placement ID', 'unity_interstitial_placement', 80);
$body .= network_input($row, 'Wortise ad unit ID', 'wortise_interstitial_unit', 80);
$body .= '<label>Monetag DirectLink<input name="monetag_link" maxlength="500" value="'
    . network_value($row, 'monetag_link') . '" placeholder="https://"></label>';
$body .= '<p class="hint">If you set more than one network that this app can show, full-screen ads appear randomly.</p>';
$body .= '<label>In-app interstitial frequency<select name="page_interval">'
    . '<option value="0"' . network_selected($row, 'page_interval', '0') . '>Off</option>'
    . '<option value="2"' . network_selected($row, 'page_interval', '2') . '>Show every 2 pages</option>'
    . '<option value="3"' . network_selected($row, 'page_interval', '3') . '>Show every 3 pages</option>'
    . '<option value="4"' . network_selected($row, 'page_interval', '4') . '>Show every 4 pages</option>'
    . '<option value="5"' . network_selected($row, 'page_interval', '5') . '>Show every 5 pages</option>'
    . '<option value="8"' . network_selected($row, 'page_interval', '8') . '>Show every 8 pages</option>'
    . '<option value="10"' . network_selected($row, 'page_interval', '10') . '>Show every 10 pages</option>'
    . '</select></label>';
$body .= '<label>Show in chats<select name="chat_interval">'
    . '<option value="0"' . network_selected($row, 'chat_interval', '0') . '>Off</option>'
    . '<option value="10"' . network_selected($row, 'chat_interval', '10') . '>Show every 10 messages sent</option>'
    . '<option value="20"' . network_selected($row, 'chat_interval', '20') . '>Show every 20 messages sent</option>'
    . '<option value="30"' . network_selected($row, 'chat_interval', '30') . '>Show every 30 messages sent</option>'
    . '<option value="50"' . network_selected($row, 'chat_interval', '50') . '>Show every 50 messages sent</option>'
    . '</select></label>';
$body .= '<label>Show on app launch<select name="launch_interval">'
    . '<option value="0"' . network_selected($row, 'launch_interval', '0') . '>Off</option>'
    . '<option value="2"' . network_selected($row, 'launch_interval', '2') . '>Show every 2 times</option>'
    . '<option value="3"' . network_selected($row, 'launch_interval', '3') . '>Show every 3 times</option>'
    . '<option value="4"' . network_selected($row, 'launch_interval', '4') . '>Show every 4 times</option>'
    . '<option value="5"' . network_selected($row, 'launch_interval', '5') . '>Show every 5 times</option>'
    . '</select></label>';
$body .= '<label>Show on first launch<select name="show_first_launch">'
    . '<option value="1"' . network_selected($row, 'show_first_launch', '1') . '>Yes</option>'
    . '<option value="0"' . network_selected($row, 'show_first_launch', '0') . '>No</option>'
    . '</select></label>';
$body .= '<label>Appnext ad type<select name="appnext_type">'
    . '<option value="interstitial"' . network_selected($row, 'appnext_type', 'interstitial') . '>Interstitial</option>'
    . '<option value="native"' . network_selected($row, 'appnext_type', 'native') . '>Native</option>'
    . '</select></label>';
$body .= network_input($row, 'AdMob app open ad ID', 'admob_app_open_unit', 80);
$body .= '<p class="hint">If you set an AdMob app open ID, the launch ad is an app-open ad instead of an interstitial.</p>';
$body .= '<button type="submit">Save network ads</button></form>';

layout('Network ads', $body, $admin);
