import os
file = 'volo/lib/add_event_page.dart'
with open(file, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('UpdateEventData(state.posterImage: File(', 'UpdateEventData(posterImage: File(')
text = text.replace('setState(() => state.currentPage = index);', '// setState(() => state.currentPage = index); // handled by step change')
text = text.replace('setState(() => eventType = cat)', 'context.read<AddEventBloc>().add(UpdateEventData(eventType: cat))')

with open(file, 'w', encoding='utf-8') as f:
    f.write(text)
