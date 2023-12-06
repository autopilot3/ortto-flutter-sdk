class LinkUtm {
    String? campaign;
    String? medium;
    String? source;
    String? content;

    LinkUtm({
        this.campaign,
        this.medium,
        this.source,
        this.content,
    });

    LinkUtm.fromMap(Map<String, dynamic> map) {
        campaign = map['utm_campaign'] as String?;
        medium = map['utm_medium'] as String?;
        source = map['utm_source'] as String?;
        content = map['utm_content'] as String?;
    }

    @override 
    String toString() {
        return 'LinkUtm{campaign: $campaign, medium: $medium, source: $source, content: $content}';
    }
}
