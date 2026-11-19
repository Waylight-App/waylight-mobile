import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/media.dart';

String _s(Object? v) => v is String ? v : '';

/// `GET /api/photos`; `album` comes from the widget's settings.
const photosQuery = WidgetQuery<List<String>>(
  '/api/photos',
  parsePhotoIds,
  query: {'album': 'Photos'},
);

/// The server path of a photo.
String photoPath(String id) => '/api/photos/${Uri.encodeComponent(id)}/image';

/// `GET /api/space/apod`.
const apodQuery = WidgetQuery<Apod>('/api/space/apod', parseApod);

/// `GET /api/mail/inbox`; `account` may narrow it to one account.
const inboxQuery = WidgetQuery<Inbox>('/api/mail/inbox', parseInbox);

/// `GET /api/drop`.
const dropQuery = WidgetQuery<List<Drop>>('/api/drop', parseDrops);

/// `GET /api/focus/stats`.
const focusQuery = WidgetQuery<List<FocusDay>>('/api/focus/stats', parseFocus);

/// The values of a custom endpoint.
WidgetQuery<ApiValues> apiValuesQuery(String endpointId) => WidgetQuery(
  '/api/apiwidget/endpoints/${Uri.encodeComponent(endpointId)}/values',
  parseApiValues,
);

/// Maps `GET /api/photos` to the ids of the photos.
List<String>? parsePhotoIds(Object? json) => listOf<String>(json, (p) {
  if (p case {'id': final String id}) return id;
  return null;
});

/// Maps `GET /api/space/apod`.
Apod? parseApod(Object? json) {
  if (json case {'title': final String title}) {
    final image = _s(json['image']);
    return Apod(
      title: title,
      // The server answers with path and query, e.g. "/api/space/apod/image?d=…".
      imagePath: json['mediaType'] == 'image' ? image : '',
      explanation: _s(json['explanation']),
      link: Uri.tryParse(_s(json['link'])),
    );
  }
  return null;
}

/// Maps `GET /api/apiwidget/endpoints/{id}/values`.
ApiValues? parseApiValues(Object? json) {
  if (json case {'name': final String name, 'values': final Object? values}) {
    final parsed = listOf<ApiValue>(values, (v) {
      if (v case {'label': final String label}) {
        final error = _s(v['error']);
        return ApiValue(
          label: label,
          text: error.isNotEmpty ? error : _s(v['text']),
          unit: error.isNotEmpty ? '' : _s(v['unit']),
          status: error.isNotEmpty ? 'error' : _s(v['status']),
        );
      }
      return null;
    });
    return parsed == null ? null : ApiValues(name: name, values: parsed);
  }
  return null;
}

/// Maps `GET /api/mail/inbox`.
Inbox? parseInbox(Object? json) {
  if (json case {'unread': final int unread, 'messages': final Object? list}) {
    final messages = listOf<MailHeader>(list, (m) {
      if (m case {'from': final String from, 'subject': final String subject}) {
        return MailHeader(
          from: from,
          subject: subject,
          date: asDateTime(m['date'])?.toLocal(),
        );
      }
      return null;
    });
    if (messages == null) return null;
    final webmail = _s(json['webmailUrl']);
    return Inbox(
      unread: unread,
      messages: messages,
      webmail: webmail.isEmpty ? null : Uri.tryParse(webmail),
    );
  }
  return null;
}

/// Maps `GET /api/drop`.
List<Drop>? parseDrops(Object? json) => listOf<Drop>(json, (d) {
  if (d case {'id': final String id, 'kind': final String kind}) {
    return Drop(
      id: id,
      isFile: kind == 'file',
      text: _s(d['text']),
      fileName: _s(d['fileName']),
      size: (d['size'] as num?)?.toInt() ?? 0,
      expiresAt: asDateTime(d['expiresAt'])?.toLocal(),
    );
  }
  return null;
});

/// Maps `GET /api/focus/stats`.
List<FocusDay>? parseFocus(Object? json) {
  if (json case {'days': final Object? days}) {
    return listOf<FocusDay>(days, (d) {
      if (d case {'date': final String date, 'minutes': final int minutes}) {
        final day = asDay(date);
        if (day == null) return null;
        return FocusDay(
          date: day,
          minutes: minutes,
          sessions: (d['sessions'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    });
  }
  return null;
}
