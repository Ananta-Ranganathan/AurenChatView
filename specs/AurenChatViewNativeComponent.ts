import type { HostComponent, ViewProps } from 'react-native';
import { codegenNativeComponent } from 'react-native';
import { CodegenTypes } from 'react-native';

export interface Message {
  uuid: string;
  text: string;
  isUser: boolean;
  readByCharacterAt?: CodegenTypes.Double;
}

export interface NativeProps extends ViewProps {
  messages: Message[];
}

export default codegenNativeComponent<NativeProps>(
  'AurenChatView',
) as HostComponent<NativeProps>;
