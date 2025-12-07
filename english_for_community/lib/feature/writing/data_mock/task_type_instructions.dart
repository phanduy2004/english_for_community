// file: task_type_instructions.dart

class TaskTypeInstruction {
  final String title;
  final String icon; // Tên icon trong thư mục assets (nếu có) hoặc iconData
  final String description;
  final String structure;
  final List<String> keyTips;

  const TaskTypeInstruction({
    required this.title,
    required this.icon,
    required this.description,
    required this.structure,
    required this.keyTips,
  });
}

const Map<String, TaskTypeInstruction> taskInstructions = {
  'Discussion': TaskTypeInstruction(
    title: 'Discussion Essay',
    icon: 'assets/icons/discussion.svg', // Ví dụ
    description: 'You need to discuss two opposing views and then give your own opinion. It is crucial to analyze both sides before stating your position.',
    structure: '''
1. Introduction:
   • Paraphrase the topic (both views).
   • State that you will discuss both views and give your opinion.

2. Body Paragraph 1 (View 1):
   • Introduce the first viewpoint.
   • Explain the arguments for this view with examples.

3. Body Paragraph 2 (View 2):
   • Introduce the second viewpoint.
   • Explain the arguments for this view with examples.

4. Conclusion & Opinion:
   • Summarize both views.
   • Clearly state your own opinion and the reason for it.
    ''',
    keyTips: [
      'Use linking words to contrast the two views (e.g., "However", "On the other hand").',
      'Make sure your opinion is clear in the conclusion, not just a repetition of the introduction.',
      'Give equal weight to discussing both views if the prompt requires it.'
    ],
  ),
  'Advantages-Disadvantages': TaskTypeInstruction(
    title: 'Advantages & Disadvantages',
    icon: 'assets/icons/advantages.svg',
    description: 'You need to discuss the benefits (pros) and drawbacks (cons) of a specific topic. You may or may not be asked for your opinion.',
    structure: '''
1. Introduction:
   • Paraphrase the topic.
   • Briefly state that there are both advantages and disadvantages (and your opinion if asked).

2. Body Paragraph 1 (Advantages):
   • Introduce the main advantage(s).
   • Explain and give examples.

3. Body Paragraph 2 (Disadvantages):
   • Introduce the main disadvantage(s).
   • Explain and give examples.

4. Conclusion:
   • Summarize the main pros and cons.
   • (Optional) State which side outweighs the other if asked for your opinion.
    ''',
    keyTips: [
      'Clearly separate advantages and disadvantages into different paragraphs.',
      'Use appropriate vocabulary (e.g., "benefit", "drawback", "upside", "downside").',
      'Pay attention to whether the question asks for your opinion ("Do the advantages outweigh the disadvantages?").'
    ],
  ),
  'Opinion': TaskTypeInstruction(
    title: 'Opinion Essay (Agree/Disagree)',
    icon: 'assets/icons/opinion.svg',
    description: 'You need to clearly state your opinion on a given topic (agree, disagree, or partially agree) and support it with strong arguments.',
    structure: '''
1. Introduction:
   • Paraphrase the topic.
   • Clearly state your opinion (thesis statement).

2. Body Paragraph 1 (Argument 1):
   • State your first reason.
   • Explain and support it with examples.

3. Body Paragraph 2 (Argument 2):
   • State your second reason.
   • Explain and support it with examples.
   • (Optional) You can address the opposing view and refute it here.

4. Conclusion:
   • Restate your opinion.
   • Summarize your main arguments.
    ''',
    keyTips: [
      'Make your opinion very clear in the introduction.',
      'Use phrases like "In my opinion", "I strongly agree/disagree".',
      'Each body paragraph should focus on one main idea supporting your opinion.'
    ],
  ),
  'Problem-Solution': TaskTypeInstruction(
    title: 'Problem & Solution Essay',
    icon: 'assets/icons/problem.svg',
    description: 'You need to identify the causes of a problem and suggest viable solutions. Sometimes you only need to discuss problems or solutions.',
    structure: '''
1. Introduction:
   • Paraphrase the problem.
   • State that you will discuss the causes/problems and suggest solutions.

2. Body Paragraph 1 (Causes/Problems):
   • Explain the main cause(s) of the problem.
   • Give examples to illustrate the problem.

3. Body Paragraph 2 (Solutions):
   • Suggest 1-2 practical solutions.
   • Explain how these solutions would work and their potential effectiveness.

4. Conclusion:
   • Summarize the main problem(s).
   • Briefly reiterate the suggested solutions.
    ''',
    keyTips: [
      'Make sure your solutions directly address the problems you mentioned.',
      'Use vocabulary related to cause and effect (e.g., "result in", "lead to", "stem from").',
      'Be realistic with your solutions.'
    ],
  ),
  'Two-part question': TaskTypeInstruction(
    title: 'Two-part Question Essay',
    icon: 'assets/icons/two-part.svg',
    description: 'You will be asked two distinct questions about a topic. You must answer both questions in your essay.',
    structure: '''
1. Introduction:
   • Paraphrase the topic.
   • Briefly outline that you will answer both questions.

2. Body Paragraph 1 (Answer Question 1):
   • Directly answer the first question.
   • Explain your answer and provide examples.

3. Body Paragraph 2 (Answer Question 2):
   • Directly answer the second question.
   • Explain your answer and provide examples.

4. Conclusion:
   • Summarize your answers to both questions.
    ''',
    keyTips: [
      'Make sure you answer BOTH questions fully.',
      'Use a separate paragraph for each question.',
      'The structure is crucial here; make it clear which paragraph addresses which question.'
    ],
  ),
  'Discuss both views and give your own opinion': TaskTypeInstruction(
    title: 'Discussion + Opinion Essay',
    icon: 'assets/icons/discussion.svg',
    description: 'This is a specific type of discussion essay where you MUST discuss two views and then give your own opinion, typically in the conclusion.',
    structure: '''
1. Introduction:
   • Paraphrase both views.
   • State that you will discuss both sides and provide your opinion.

2. Body Paragraph 1 (View 1):
   • Analyze the first viewpoint. Why do some people hold this view?

3. Body Paragraph 2 (View 2):
   • Analyze the second viewpoint. Why do others hold this view?

4. Conclusion & Opinion:
   • Summarize the key points of both views.
   • Clearly state your own opinion and briefly explain which view you side with and why.
    ''',
    keyTips: [
      'Do not state your opinion too strongly in the introduction; save it for the conclusion.',
      'Ensure both views are discussed in a balanced way before giving your verdict.',
      'Use clear transition signals to move from one view to the other and then to your opinion.'
    ],
  ),
};