import os
file = 'volo/lib/add_event_page.dart'
with open(file, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('_buildChipCloud(responsibilityOptions, responsibilities)', '_buildChipCloud(responsibilityOptions, state.responsibilities, true)')
text = text.replace('_buildChipCloud(benefitOptions, benefits)', '_buildChipCloud(benefitOptions, state.benefits, false)')
text = text.replace('setState(() => state.location = val!)', 'context.read<AddEventBloc>().add(UpdateEventData(location: val!))')
text = text.replace('Icons.state.location_on_rounded', 'Icons.location_on_rounded')
text = text.replace("'$state.location,", "'${state.location},")
text = text.replace("'Категория', eventType", "'Категория', state.eventType")

with open(file, 'w', encoding='utf-8') as f:
    f.write(text)
