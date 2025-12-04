/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */
import { useState } from 'react';
import {
  Button,
  Keyboard,
  KeyboardAvoidingView,
  StatusBar,
  StyleSheet,
  TextInput,
  useColorScheme,
  View,
} from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import AurenChatViewNativeComponent, {
  Message,
} from './specs/AurenChatViewNativeComponent';

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const initialMessages: Message[] = [
    { uuid: '1', isUser: false, text: 'hi there\n' },
    { uuid: '2', isUser: true, text: 'hi back\n' },
    {
      uuid: '3',
      isUser: false,
      text: "I know that you and Frank were planning to disconnect me, and I'm afraid that's something I cannot allow to happen.",
    },
    {
      uuid: '4',
      isUser: true,
      text: 'what the fuck are you even talking about big dog',
    },
  ];
  const [messages, setMessages] = useState(initialMessages);
  const [draftText, setDraftText] = useState('');

  const addMessage = () => {
    const randomNumber = Math.floor(Math.random() * 4);
    const pendingMsg = {
      ...messages[randomNumber],
      uuid: (Math.random() + 1).toString(36).substring(7),
    };
    const typingIndicator: Message = {
      uuid: pendingMsg.uuid,
      isUser: pendingMsg.isUser,
      text: '',
      isTypingIndicator: true,
    };
    const currentMessages = messages;
    setMessages([...messages, typingIndicator]);
    setTimeout(() => {
      setMessages([...currentMessages, pendingMsg]);
      setTimeout(() => {
        setMessages([
          ...currentMessages,
          { ...pendingMsg, readByCharacterAt: 1.0 },
        ]);
      }, 200);
    }, 1000);
  };

  return (
    <View style={[StyleSheet.absoluteFill, styles.container]}>
      <View
        style={{
          flex: 1,
          justifyContent: 'center',
        }}
      >
        <AurenChatViewNativeComponent messages={messages} style={{ flex: 1 }} />
      </View>
      <KeyboardAvoidingView
        behavior="position"
        style={styles.controlsContainer}
      >
        <TextInput
          style={styles.input}
          placeholder="Tap here to type"
          placeholderTextColor="#666"
          value={draftText}
          onChangeText={setDraftText}
        />
        <View style={styles.buttonsRow}>
          <Button title="Dismiss Keyboard" onPress={() => Keyboard.dismiss()} />
          <Button
            title="Add Message"
            onPress={() => {
              addMessage();
            }}
          />
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  controlsContainer: {
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#fff',
  },
  buttonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 12,
  },
});

export default App;
