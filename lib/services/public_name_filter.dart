/// Immediate user feedback; trusted Firebase callable is authoritative.
class PublicNameFilter {
  PublicNameFilter._();
  static final Set<String> _blocked = {
    'fuck','fucker','fucking','fuk','shit','shite','bitch','cunt',
    'cock','pussy','arsehole','asshole','wanker','twat','bastard',
    'slut','whore','nigger','nigga','faggot','nonce','paedo','pedo',
    'motherfucker','dickhead','bullshit','bollocks',
  };
  static const _severe = ['fuck','cunt','nigger','nigga','faggot','motherfucker'];
  static bool isBlocked(String input) {
    String value = input.toLowerCase();
    const substitutions = {'@':'a','4':'a','0':'o','1':'i','3':'e','5':'s','7':'t'};
    substitutions.forEach((from,to) => value=value.replaceAll(from,to));
    final tokens = RegExp(r'[a-z]+').allMatches(value).map((m)=>m.group(0)!);
    if (tokens.any(_blocked.contains)) return true;
    String compact = value.replaceAll(RegExp(r'[^a-z]'), '');
    compact = compact.replaceAllMapped(RegExp(r'(.)\1{2,}'),(m)=>'${m.group(1)}${m.group(1)}');
    if (_severe.any(compact.contains)) return true;
    return RegExp(r'^(rhi\s*play|first\s*guess)\s*(admin|staff|support|official|moderator)$', caseSensitive:false).hasMatch(input.trim());
  }
}
