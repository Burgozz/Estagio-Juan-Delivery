package com.juan.api_delivery.usuario;

import com.juan.api_delivery.auth.CredenciaisInvalidasException;
import com.juan.api_delivery.shared.validation.CpfValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static com.juan.api_delivery.shared.exception.MensagensErro.EMAIL_JA_CADASTRADO;
import static com.juan.api_delivery.shared.exception.MensagensErro.USUARIO_NAO_ENCONTRADO;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository repository;

    public List<Usuario> listarTodos() {
        return repository.findByAtivoTrue();
    }

    /**
     * Usado pela tela de administração: retorna todos os usuários,
     * incluindo os inativos.
     */
    public List<Usuario> listarTodosAdmin() {
        return repository.findAll();
    }

    public Usuario buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new RuntimeException(USUARIO_NAO_ENCONTRADO));
    }

    public Usuario criar(UsuarioDTO dto) {
        Optional<Usuario> existente = repository.findByEmail(dto.getEmail());
        if (existente.isPresent()) {
            Usuario usuario = existente.get();
            if (usuario.isAtivo()) {
                throw new IllegalArgumentException(EMAIL_JA_CADASTRADO);
            }
            usuario.setNome(dto.getNome());
            usuario.setCpf(CpfValidator.somenteDigitos(dto.getCpf()));
            usuario.setSenha(dto.getSenha());
            usuario.setTelefone(dto.getTelefone());
            usuario.setDataCadastro(LocalDate.now());
            usuario.setAtivo(true);
            usuario.setPerfil(PerfilUsuario.CLIENTE);
            return repository.save(usuario);
        }
        Usuario usuario = Usuario.builder()
        .nome(dto.getNome())
        .cpf(CpfValidator.somenteDigitos(dto.getCpf()))
        .email(dto.getEmail())
        .senha(dto.getSenha())
        .telefone(dto.getTelefone())
        .dataCadastro(LocalDate.now())
        .perfil(PerfilUsuario.CLIENTE)
        .build();
    return repository.save(usuario);
    }

    public Usuario atualizar(Long id, UsuarioDTO dto) {
        Usuario usuario = buscarPorId(id);
    repository.findByEmail(dto.getEmail())
        .filter(u -> !u.getId().equals(id))
        .ifPresent(u -> { throw new IllegalArgumentException(EMAIL_JA_CADASTRADO); });
    usuario.setNome(dto.getNome());
    usuario.setCpf(CpfValidator.somenteDigitos(dto.getCpf()));
    usuario.setEmail(dto.getEmail());
    usuario.setSenha(dto.getSenha());
    usuario.setTelefone(dto.getTelefone());
    return repository.save(usuario);
    }

    public void deletar(Long id) {
        Usuario usuario = buscarPorId(id);
        usuario.setAtivo(false);
        repository.save(usuario);
    }

    public Usuario login(String email, String senha) {
        Usuario usuario = repository.findByEmail(email)
            .filter(Usuario::isAtivo)
            .orElseThrow(CredenciaisInvalidasException::new);
        if (!usuario.getSenha().equals(senha)) {
            throw new CredenciaisInvalidasException();
        }
        return usuario;
    }
}